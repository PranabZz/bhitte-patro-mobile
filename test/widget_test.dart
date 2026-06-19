// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:bhitte_patro/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GreetingHeader displays greeting based on time of day',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GreetingHeader(),
          ),
        ),
      ),
    );

    final morningFinder = find.textContaining('Good Morning');
    final afternoonFinder = find.textContaining('Good Afternoon');
    final eveningFinder = find.textContaining('Good Evening');
    final nightFinder = find.textContaining('Good Night');

    final foundAny = morningFinder.evaluate().isNotEmpty ||
        afternoonFinder.evaluate().isNotEmpty ||
        eveningFinder.evaluate().isNotEmpty ||
        nightFinder.evaluate().isNotEmpty;

    expect(foundAny, isTrue);
  });
}
