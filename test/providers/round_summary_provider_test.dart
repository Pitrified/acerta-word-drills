import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:acerta/providers/round_summary_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: roundOverrides(
        cards: fakeCardRepository(12),
        progress: FakeProgressRepository(),
      ),
    );
    addTearDown(container.dispose);
  });

  test('is null before a round', () {
    expect(container.read(roundSummaryProvider), isNull);
  });

  test('has one entry per pair, in round order', () async {
    await container.read(roundProvider.notifier).start();
    final round = container.read(roundProvider).round!;
    final summary = container.read(roundSummaryProvider)!;
    expect(summary.entries.map((e) => e.pair), round.pairs);
  });

  test('marks the missed cards and counts the right first time', () async {
    final notifier = container.read(roundProvider.notifier);
    await notifier.start();
    final pairs = container.read(roundProvider).round!.pairs;
    await notifier.tapLeft(pairs[0].left);
    await notifier.tapRight(pairs[1].right);
    for (final pair in pairs) {
      await notifier.tapLeft(pair.left);
      await notifier.tapRight(pair.right);
    }
    final summary = container.read(roundSummaryProvider)!;
    expect(
      {for (final e in summary.entries) e.pair.card.id: e.missed},
      {for (final pair in pairs) pair.card.id: pair == pairs[0]},
    );
    expect(summary.rightFirstTime, pairs.length - 1);
  });

  test('follows the hidden flag of the progress', () async {
    await container.read(roundProvider.notifier).start();
    final id = container.read(roundSummaryProvider)!.entries.first.pair.card.id;
    expect(container.read(roundSummaryProvider)!.entries.first.hidden, isFalse);
    await container.read(progressProvider.notifier).setHidden(id, hidden: true);
    expect(container.read(roundSummaryProvider)!.entries.first.hidden, isTrue);
  });
}
