/// «وثائقي» — وثائق ملفّي الوظيفي بتواريخ انتهائها ونغمة الرادار الخادمية.
///
/// المعاينة من الذاكرة فقط (لا تهبط القرص — وثائق شخصية حساسة) وللصور؛ وما
/// سواها يُذكر بصدق أنه لا يُعاين في التطبيق — لا زرّ يوهم بفتحٍ لا يحدث.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/di/app_scope.dart';
import '../../core/errors/api_exception.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'my_documents_repository.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  List<MyDocument>? _docs;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await AppScope.of(context).myDocuments.list();
      if (mounted) setState(() => _docs = docs);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.myDocumentsTitle)),
      body: AsyncView<List<MyDocument>>(
        loading: _loading,
        error: _error,
        value: _docs,
        onRetry: _load,
        emptyWhen: (d) => d.isEmpty,
        emptyMessage: l.myDocumentsEmpty,
        builder: (context, docs) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final d in docs) _DocTile(doc: d),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.myDocumentsNoPersist,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc});

  final MyDocument doc;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final d = doc;
    final toneColor = switch (d.tone) {
      'bad' => theme.colorScheme.error,
      'wn' => Colors.orange,
      _ => null,
    };
    final expiry = d.expiresOn == null
        ? null
        : (d.daysLeft != null && d.daysLeft! < 0
              ? l.myDocumentsExpired(d.expiresOn!)
              : l.myDocumentsExpires(d.expiresOn!));
    final canPreview = d.isImage && !d.infected;
    final lines = [
      if (d.name.isNotEmpty) d.name,
      if (d.docNo != null) l.myDocumentsNo(d.docNo!),
      if (d.infected)
        l.myDocumentsInfected
      else if (!d.isImage)
        l.myDocumentsNoPreview,
    ];
    return Card(
      key: Key('mydoc-${d.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          d.infected
              ? Icons.gpp_bad_outlined
              : (d.isImage ? Icons.image_outlined : Icons.description_outlined),
          color: d.infected ? theme.colorScheme.error : null,
        ),
        title: Text(d.label),
        subtitle: Text(lines.join('\n')),
        isThreeLine: lines.length > 1,
        trailing: expiry == null
            ? (canPreview ? const Icon(Icons.chevron_right) : null)
            : Text(
                expiry,
                style: theme.textTheme.bodySmall?.copyWith(color: toneColor),
              ),
        onTap: canPreview
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MyDocumentPreviewScreen(doc: d),
                ),
              )
            : null,
      ),
    );
  }
}

/// معاينة صورة وثيقة من الذاكرة — البايتات تُترك مع الشاشة، لا ملف ولا خبيئة.
class MyDocumentPreviewScreen extends StatefulWidget {
  const MyDocumentPreviewScreen({super.key, required this.doc});

  final MyDocument doc;

  @override
  State<MyDocumentPreviewScreen> createState() =>
      _MyDocumentPreviewScreenState();
}

class _MyDocumentPreviewScreenState extends State<MyDocumentPreviewScreen> {
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await AppScope.of(context).myDocuments.file(widget.doc.id);
      if (mounted) setState(() => _bytes = bytes);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _bytes = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = _error;
    // المنع الصريح (٤٠٣) والإصابة (٤٢٣) حالتان معروفتان بنصٍّ محلي من الرمز.
    final known = e is ApiException
        ? switch (e.code) {
            ApiErrorCode.forbidden => l.myDocumentsRestricted,
            ApiErrorCode.locked => l.myDocumentsInfected,
            _ => null,
          }
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.doc.label)),
      body: known != null
          ? EmptyView(message: known, icon: Icons.lock_outline)
          : AsyncView<Uint8List>(
              loading: _loading,
              error: _error,
              value: _bytes,
              onRetry: _load,
              emptyWhen: (b) => b.isEmpty,
              builder: (context, bytes) => InteractiveViewer(
                child: Center(
                  child: Image.memory(
                    bytes,
                    key: const Key('mydoc-image'),
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) =>
                        EmptyView(message: l.myDocumentsNoPreview),
                  ),
                ),
              ),
            ),
    );
  }
}
