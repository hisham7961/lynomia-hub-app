/// أفعال مالية مختارة (المرحلة ٤.٦) عبر المحرّكات الموحّدة: تسجيل دفعة
/// (`fin/{id}/pay` ⇐ JournalPosting، خلف تصعيد `action:fin:pay`)، إرسال/قبول
/// عرض السعر (`quotes/{id}/send|accept`)، استلام أمر الشراء
/// (`purchases/{id}/receive`). كلها بمفتاح Idempotency ثابت للفعل الواحد،
/// والمال عشريٌّ نصّاً (`Decimal`) لا double — والخادم يحسب.
library;

import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json_read.dart';

class FinDocumentCard {
  const FinDocumentCard({
    required this.id,
    this.docNo,
    this.state,
    this.currency,
    this.total,
    this.paid,
    this.remaining,
  });

  factory FinDocumentCard.fromJson(Map<String, dynamic> j) => FinDocumentCard(
    id: j['id']?.toString() ?? '',
    docNo: jsonStr(j['doc_no']),
    state: jsonStr(j['state']),
    currency: jsonStr(j['currency']),
    total: jsonDecimal(j['total']),
    paid: jsonDecimal(j['paid']),
    remaining: jsonDecimal(j['remaining']),
  );

  final String id;
  final String? docNo;
  final String? state;
  final String? currency;

  /// null حين يُحجب الحقل عن الدور.
  final Decimal? total;
  final Decimal? paid;
  final Decimal? remaining;
}

class FinPaymentResult {
  const FinPaymentResult({required this.amount, required this.document});

  factory FinPaymentResult.fromJson(Map<String, dynamic> j) => FinPaymentResult(
    amount: jsonDecimal(j['amount']),
    document: FinDocumentCard.fromJson(jsonMap(j['document'])),
  );

  final Decimal? amount;
  final FinDocumentCard document;
}

class QuoteCard {
  const QuoteCard({required this.id, this.docNo, this.status});

  factory QuoteCard.fromJson(Map<String, dynamic> j) => QuoteCard(
    id: j['id']?.toString() ?? '',
    docNo: jsonStr(j['doc_no']),
    status: jsonStr(j['status']),
  );

  final String id;
  final String? docNo;
  final String? status;
}

class PurchaseReceipt {
  const PurchaseReceipt({
    required this.moves,
    required this.skipped,
    required this.already,
    this.status,
  });

  factory PurchaseReceipt.fromJson(Map<String, dynamic> j) => PurchaseReceipt(
    moves: jsonInt(j['moves']),
    skipped: jsonInt(j['skipped']),
    already: j['already'] == true,
    status: jsonStr(jsonMap(j['purchase'])['status']),
  );

  final int moves;
  final int skipped;
  final bool already;
  final String? status;
}

/// أسباب عدم إتاحة الدفعة الآلية (`fin/{id}/pay-options`).
abstract final class PayDenyReason {
  static const deadState = 'dead_state';
  static const settled = 'settled';
}

class PayBank {
  const PayBank({required this.id, required this.name, this.currency});

  factory PayBank.fromJson(Map<String, dynamic> j) => PayBank(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    currency: jsonStr(j['currency']),
  );

  final String id;
  final String name;
  final String? currency;
}

/// خيارات نموذج الدفعة بلا أثر ولا تصعيد (خلفية v2.619) — ما يعرضه نموذج
/// الويب لمن يملك الفعل. `canPay` عرضٌ؛ حرّاس البنك تبقى عند الفعل.
class PayOptions {
  const PayOptions({
    required this.id,
    required this.canPay,
    required this.banks,
    this.reason,
    this.remaining,
    this.currency,
    this.defaultBankId,
    this.stepUpPurpose,
  });

  factory PayOptions.fromJson(Map<String, dynamic> j) {
    final banks = jsonMaps(j['banks']).map(PayBank.fromJson).toList();
    final def = jsonStr(j['default_bank_id']);
    return PayOptions(
      id: j['id']?.toString() ?? '',
      canPay: j['can_pay'] == true,
      reason: jsonStr(j['reason']),
      remaining: jsonDecimal(j['remaining']),
      currency: jsonStr(j['currency']),
      banks: banks,
      // البنك الافتراضي لا يُعتمد إلا إن كان بين المعروض (الخادم يضمنه — ونتحقق).
      defaultBankId: banks.any((b) => b.id == def) ? def : null,
      stepUpPurpose: jsonStr(j['step_up_purpose']),
    );
  }

  final String id;
  final bool canPay;

  /// `dead_state` | `settled` | null.
  final String? reason;

  /// عشريٌّ من نصّ — null حين يُحجب الإجمالي أو المدفوع عن الدور.
  final Decimal? remaining;
  final String? currency;
  final List<PayBank> banks;
  final String? defaultBankId;
  final String? stepUpPurpose;
}

/// يطبّع مبلغاً أدخله المستخدم إلى عشريٍّ صريح بلا فواصل (يرفض ما سواه).
Decimal? parseAmount(String raw) {
  // الأرقام الهندية (U+0660–U+0669) والفاصل العشري العربي (U+066B) ⇒ لاتينية.
  var s = raw.trim();
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(String.fromCharCode(0x0660 + i), '$i');
  }
  s = s.replaceAll(String.fromCharCode(0x066B), '.');
  if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(s)) return null;
  final d = Decimal.tryParse(s);
  if (d == null || d <= Decimal.zero) return null;
  return d;
}

class FinanceRepository {
  FinanceRepository(this.api);

  final ApiClient api;

  /// `GET fin/{id}/pay-options` — بلا أثر (403 بلا `fin:e`، 404 خارج النطاق).
  Future<PayOptions> payOptions(String finId) async => PayOptions.fromJson(
    await api.getData('fin/${Uri.encodeComponent(finId)}/pay-options'),
  );

  /// `POST fin/{id}/pay` — المبلغ نصٌّ عشري؛ خلف التصعيد (428 ⇒ runWithStepUp).
  Future<FinPaymentResult> pay(
    String finId, {
    required Decimal amount,
    String? bankId,
    DateTime? payDate,
    String? payRef,
    String? payNote,
    String? idempotencyKey,
  }) async => FinPaymentResult.fromJson(
    await api.sendData(
      'POST',
      'fin/${Uri.encodeComponent(finId)}/pay',
      body: {
        'amount': amount.toString(),
        if (bankId != null && bankId.isNotEmpty) 'bankId': bankId,
        if (payDate != null)
          'payDate':
              '${payDate.year.toString().padLeft(4, '0')}-'
              '${payDate.month.toString().padLeft(2, '0')}-'
              '${payDate.day.toString().padLeft(2, '0')}',
        if (payRef != null && payRef.trim().isNotEmpty) 'payRef': payRef.trim(),
        if (payNote != null && payNote.trim().isNotEmpty)
          'payNote': payNote.trim(),
      },
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );

  /// `POST quotes/{id}/send` ⇒ `sent` | `escalated` (للمراجعة الداخلية).
  Future<({String outcome, QuoteCard quote})> sendQuote(
    String quoteId, {
    String? idempotencyKey,
  }) async {
    final d = await api.sendData(
      'POST',
      'quotes/${Uri.encodeComponent(quoteId)}/send',
      body: const {},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return (
      outcome: d['outcome']?.toString() ?? '',
      quote: QuoteCard.fromJson(jsonMap(d['quote'])),
    );
  }

  /// `POST quotes/{id}/accept` — المتكرّر بلا أثر (`accepted=false`).
  Future<({bool accepted, QuoteCard quote})> acceptQuote(
    String quoteId, {
    String? idempotencyKey,
  }) async {
    final d = await api.sendData(
      'POST',
      'quotes/${Uri.encodeComponent(quoteId)}/accept',
      body: const {},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    );
    return (
      accepted: d['accepted'] == true,
      quote: QuoteCard.fromJson(jsonMap(d['quote'])),
    );
  }

  /// `POST purchases/{id}/receive` — حركات مخزون مؤكّدة.
  Future<PurchaseReceipt> receivePurchase(
    String purchaseId, {
    String? idempotencyKey,
  }) async => PurchaseReceipt.fromJson(
    await api.sendData(
      'POST',
      'purchases/${Uri.encodeComponent(purchaseId)}/receive',
      body: const {},
      idempotencyKey: idempotencyKey ?? const Uuid().v4(),
    ),
  );
}
