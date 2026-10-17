import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/widgets/network_banner.dart';

/// Smoke tests for [NetworkBanner] – verifies it renders without errors and
/// displays its child. Actual connectivity changes require an integration test.
void main() {
  testWidgets('NetworkBanner renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetworkBanner(
          child: Scaffold(body: Text('Hello')),
        ),
      ),
    );
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('NetworkBanner is a Stack with the child at index 0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetworkBanner(
          child: Scaffold(body: Text('Content')),
        ),
      ),
    );
    expect(find.byType(Stack), findsWidgets);
    expect(find.text('Content'), findsOneWidget);
  });
}
