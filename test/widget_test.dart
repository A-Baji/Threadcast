// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:threadcast/main.dart';

void main() {
  testWidgets('Threadcast app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ThreadcastApp());

    // Wait for the app to settle (handles async redirects, providers, etc.)
    await tester.pumpAndSettle();

    // Verify that the Create screen loads with expected elements
    expect(find.text('Create Podcast'), findsOneWidget);
    expect(find.text('Reddit URL'), findsOneWidget);
    expect(find.text('Generate (Mock)'), findsOneWidget);
  });
}
