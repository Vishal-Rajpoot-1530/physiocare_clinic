import 'package:flutter/material.dart';

import '../db/app_db.dart';

/// Loads data and automatically reloads whenever the database changes.
/// Keeps showing the old data while reloading (no flicker) and shows
/// a readable error instead of an endless spinner.
class Live<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? placeholder;
  final T? fallbackData;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;

  const Live({
    super.key,
    required this.load,
    required this.builder,
    this.placeholder,
    this.fallbackData,
    this.errorBuilder,
  });

  @override
  State<Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<Live<T>> {
  T? _data;
  Object? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AppDb.i.tick.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    AppDb.i.tick.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return widget.placeholder ??
          const Center(
            child: CircularProgressIndicator(color: Color(0xfff9a31a)),
          );
    }
    if (_error != null && _data == null) {
      final buildError = widget.errorBuilder;
      if (buildError != null) {
        return buildError(context, _error!, _reload);
      }
      final fallback = widget.fallbackData;
      if (fallback != null) {
        final message = _error.toString().replaceFirst(
          RegExp(r'^(Exception|StateError|Bad state):\s*'),
          '',
        );
        return Column(
          children: [
            Material(
              color: const Color(0xfffff4df),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 18,
                      color: Color(0xff9a5b00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data unavailable: $message',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff754500),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Retry loading data',
                      visualDensity: VisualDensity.compact,
                      onPressed: _reload,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: Color(0xff754500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: widget.builder(context, fallback)),
          ],
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              Text('Could not load data\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              TextButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return widget.builder(context, _data as T);
  }
}
