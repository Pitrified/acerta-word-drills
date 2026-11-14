import 'package:acerta/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen shows the title and the placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: AcertaApp()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'acerta'), findsOneWidget);
    expect(find.text('Pair matching is on its way.'), findsOneWidget);
  });
}
