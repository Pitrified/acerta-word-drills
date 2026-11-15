import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_card.dart';
import '../services/learn/learn_repository.dart';
import 'cards_provider.dart';
import 'clock_provider.dart';
import 'provider_not_overridden_error.dart';

/// The learn store; `main` overrides it with the opened box.
final learnRepositoryProvider = Provider<LearnRepository>(
  (ref) => throw ProviderNotOverriddenError('learnRepositoryProvider'),
);

/// The time each word was marked to learn, by card id.
final learnProvider = NotifierProvider<LearnNotifier, Map<String, DateTime>>(
  LearnNotifier.new,
);

/// Writes the marks through the repository and refreshes the state.
class LearnNotifier extends Notifier<Map<String, DateTime>> {
  LearnRepository get _repository => ref.read(learnRepositoryProvider);

  @override
  Map<String, DateTime> build() => ref.read(learnRepositoryProvider).all;

  /// Marks the word [id] now.
  Future<void> add(String id) async {
    await _repository.add(id, ref.read(clockProvider)().toUtc());
    state = _repository.all;
  }

  /// Takes the mark of the word [id] back.
  Future<void> remove(String id) async {
    await _repository.remove(id);
    state = _repository.all;
  }
}

/// A word marked to learn, with the time of the mark.
typedef LearnWord = ({WordCard card, DateTime markedAt});

/// The words marked to learn, newest mark first.
///
/// An id that is not in the card set any more is skipped.
final learnWordsProvider = Provider<AsyncValue<List<LearnWord>>>((ref) {
  final marks = ref.watch(learnProvider);
  return ref.watch(cardRepositoryProvider).whenData((cards) {
    final words = <LearnWord>[];
    for (final entry in marks.entries) {
      final card = cards.byId(entry.key);
      if (card != null) words.add((card: card, markedAt: entry.value));
    }
    return words..sort((a, b) => b.markedAt.compareTo(a.markedAt));
  });
});
