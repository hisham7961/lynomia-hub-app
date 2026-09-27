/// التفضيلات الخادمية (§79 §80) — كتم أنواع الإشعارات وتثبيت الوجهات المفضّلة.
///
/// كلها على الخادم عبر `prefs*` (نظير الويب — `PrefService`): الكتم استبدالٌ
/// كامل عديم الأثر، والتثبيت تبديلٌ بمفتاح idempotency للنقرة الواحدة وسقفٍ
/// خادمي. لا حالة محلية تُعدّ حقيقة — كل عرضٍ يُعاد من رد الخادم.
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'prefs_repository.dart';

class PrefsScreen extends StatefulWidget {
  const PrefsScreen({super.key});

  @override
  State<PrefsScreen> createState() => _PrefsScreenState();
}

class _PrefsScreenState extends State<PrefsScreen> {
  ServerPrefs? _prefs;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  String _filter = '';

  PrefsRepository get _repo => AppScope.of(context).serverPrefs;

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
      final p = await _repo.fetch();
      if (mounted) setState(() => _prefs = p);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setMuted(MuteableKind kind, bool muted) async {
    final current = _prefs;
    if (current == null) return;
    final next = {...current.muted};
    muted ? next.add(kind.key) : next.remove(kind.key);
    await _mutate(() => _repo.setMute(next.toList()));
  }

  Future<void> _togglePin(PinTarget t) async {
    // مفتاح للنقرة الواحدة — إعادة المحاولة العابرة لا تعكس التثبيت (§58).
    final key = const Uuid().v4();
    await _mutate(() => _repo.togglePin(t.token, idempotencyKey: key));
  }

  /// تعديلٌ ثم إعادة جلبٍ من الخادم (الحقيقة) — والخطأ برمزه لا بنصه.
  Future<void> _mutate(Future<Object?> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
      final fresh = await _repo.fetch();
      if (mounted) setState(() => _prefs = fresh);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeError(context, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.prefsTitle),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: AsyncView<ServerPrefs>(
        loading: _loading,
        error: _error,
        value: _prefs,
        onRetry: _load,
        builder: (context, p) {
          final q = _filter.trim();
          final targets = q.isEmpty
              ? p.pinTargets
              : p.pinTargets.where((t) => t.label.contains(q)).toList();
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.accountNotificationPrefs,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l.prefsMuteHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: p.muteable.isEmpty
                      ? ListTile(title: Text(l.stateEmpty))
                      : Column(
                          children: [
                            for (final k in p.muteable)
                              SwitchListTile(
                                key: Key('mute-${k.key}'),
                                title: Text(k.label),
                                subtitle: Text(
                                  k.muted ? l.prefsMuted : l.prefsNotifying,
                                ),
                                value: !k.muted,
                                onChanged: _busy
                                    ? null
                                    : (notify) => _setMuted(k, !notify),
                              ),
                          ],
                        ),
                ),
                Text(
                  l.pinnedTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l.prefsPinsCount(p.pinned.length, p.pinMax),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: l.prefsPinsFilter,
                    prefixIcon: const Icon(Icons.filter_list),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
                const SizedBox(height: 8),
                Card(
                  child: targets.isEmpty
                      ? ListTile(title: Text(l.stateEmpty))
                      : Column(
                          children: [
                            for (final t in targets)
                              ListTile(
                                key: Key('pin-${t.token}'),
                                title: Text(t.label),
                                trailing: IconButton(
                                  tooltip: t.pinned ? l.prefsUnpin : l.prefsPin,
                                  icon: Icon(
                                    t.pinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                  ),
                                  onPressed: _busy ? null : () => _togglePin(t),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
