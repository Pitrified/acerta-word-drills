import 'package:acerta/providers/cards_provider.dart';
import 'package:acerta/providers/clock_provider.dart';
import 'package:acerta/providers/learn_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late FakeLearnRepository learn;
  late ProviderContainer container;

  ProviderContainer containerWith(FakeLearnRepository repository) {
    final made = ProviderContainer(
      overrides: [
        learnRepositoryProvider.overrideWithValue(repository),
        cardRepositoryProvider.overrideWith(
          (ref) => Future.value(fakeCardRepository(4)),
        ),
        clockProvider.overrideWithValue(() => fixedNow),
      ],
    );
    addTearDown(made.dispose);
    return made;
  }

  setUp(() {
    learn = FakeLearnRepository();
    container = containerWith(learn);
  });

  LearnNotifier notifier() => container.read(learnProvider.notifier);

  test('starts from the repository', () {
    final other = containerWith(FakeLearnRepository({'id1': fixedNow}));
    expect(other.read(learnProvider).keys, ['id1']);
  });

  test('add stores the id with the clock time in UTC', () async {
    await notifier().add('id1');
    expect(container.read(learnProvider), {'id1': fixedNow});
    expect(learn.all, {'id1': fixedNow});
    expect(learn.all['id1']!.isUtc, isTrue);
  });

  test('remove drops the id', () async {
    await notifier().add('id1');
    await notifier().add('id2');
    await notifier().remove('id1');
    expect(container.read(learnProvider).keys, ['id2']);
    expect(learn.all.keys, ['id2']);
  });

  test(
    'learnWordsProvider lists newest mark first and skips unknown ids',
    () async {
      final other = containerWith(
        FakeLearnRepository({
          'id1': DateTime.utc(2026, 1, 1),
          'gone': DateTime.utc(2026, 1, 5),
          'id3': DateTime.utc(2026, 1, 3),
          'id2': DateTime.utc(2026, 1, 2),
        }),
      );
      final words = await other
          .read(cardRepositoryProvider.future)
          .then((_) => other.read(learnWordsProvider).value!);
      expect(words.map((w) => w.card.id), ['id3', 'id2', 'id1']);
      expect(words.first.markedAt, DateTime.utc(2026, 1, 3));
    },
  );
}
