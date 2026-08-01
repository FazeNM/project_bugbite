import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_bugbite/app/app.dart';

void main() {
  testWidgets('BiteWise opens on the sign-in experience', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('BiteWise'), findsOneWidget);
    expect(find.text('Welcome back'.toUpperCase()), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('signing in reaches visual guides and guide detail', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Common bite guides'), findsOneWidget);
    await tester.tap(find.text('Mosquito').first);
    await tester.pumpAndSettle();

    expect(find.text('Gentle next steps'), findsOneWidget);
  });

  testWidgets('symptom filters open possible visual matches', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Itchy'));
    await tester.pumpAndSettle();

    expect(find.text('What do you notice?'), findsOneWidget);
    expect(find.textContaining('possible guides'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const ProviderScope(child: BiteWiseApp()));
  await tester.pumpAndSettle();
}
