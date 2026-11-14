import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cards/card_repository.dart';

/// The word cards, loaded once from the bundled asset.
final cardRepositoryProvider = FutureProvider<CardRepository>(
  (ref) => CardRepository.load(rootBundle),
);
