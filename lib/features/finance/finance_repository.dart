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

  /// `POST fin/{id}/pay` — المبلغ نصٌّ عشري؛ خلف التصعيد (428 ⇒ runWithStepUp).
  Future<FinPaymentResult> pay(
    String finId, {
    required Decimal amount,
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
