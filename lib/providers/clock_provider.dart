import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time; tests replace it with a fixed one.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The random source of the draw and the shuffle; tests seed it.
final randomProvider = Provider<Random>((ref) => Random());
