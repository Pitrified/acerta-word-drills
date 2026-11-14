import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/logging/app_logger.dart';

/// Shows an [AsyncValue]: a spinner while it loads, [errorText] when it fails,
/// and [builder] once it has data.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.builder,
    this.errorText = 'The words could not be loaded.',
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final String errorText;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        AppLogger.instance.error('Reading the words failed', cause: error);
        return Center(child: Text(errorText));
      },
      data: builder,
    );
  }
}
