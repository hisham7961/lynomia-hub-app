/// البحث الشامل (§50) — إبطال مهلة (debounce) وإلغاء النتائج البائتة، وكل
/// نتيجة وجهة `{module,id}` تُفتح بالملاحة العامة. لا بحث في خبيئة كسلطة.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/app_scope.dart';
import '../../core/ui/async_view.dart';
import '../../l10n/app_localizations.dart';
import 'search_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _generation = 0; // إسقاط الردود البائتة (إلغاء منطقي)
  List<SearchHit>? _hits;
  Object? _error;
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(q.trim()));
  }

  Future<void> _run(String q) async {
    final gen = ++_generation;
    if (q.length < 2) {
      setState(() {
        _hits = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hits = await AppScope.of(context).search.search(q);
      if (mounted && gen == _generation) setState(() => _hits = hits);
    } on Object catch (e) {
      if (mounted && gen == _generation) setState(() => _error = e);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: _onQueryChanged,
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_loading) return const Center(child: CircularProgressIndicator());
          if (_error != null) {
            return ErrorView(
              error: _error!,
              onRetry: () => _run(_controller.text.trim()),
            );
          }
          final hits = _hits;
          if (hits == null) {
            return EmptyView(message: l.searchMinChars, icon: Icons.search);
          }
          if (hits.isEmpty) {
            return EmptyView(
              message: l.searchNoResults,
              icon: Icons.search_off,
            );
          }
          return ListView.builder(
            itemCount: hits.length,
            itemBuilder: (context, i) {
              final hit = hits[i];
              return ListTile(
                title: Text(
                  hit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(hit.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(hit.target.routePath),
              );
            },
          );
        },
      ),
    );
  }
}
