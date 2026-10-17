import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/widgets/network_banner.dart';

/// Smoke tests for [NetworkBanner] – verifies it renders without errors and
/// displays its child. Actual connectivity changes require an integration test.
void main() {
  testWidgets('NetworkBanner renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetworkBanner(child: Scaffold(body: Text('Hello'))),
      ),
    );
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('NetworkBanner is a Stack with the child at index 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetworkBanner(child: Scaffold(body: Text('Content'))),
      ),
    );
    expect(find.byType(Stack), findsWidgets);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('shows offline then briefly confirms reconnection', (
    tester,
  ) async {
    final changes = StreamController<List<ConnectivityResult>>();
    addTearDown(changes.close);

    await tester.pumpWidget(
      MaterialApp(
        home: NetworkBanner(
          checkConnectivity: () async => [ConnectivityResult.none],
          connectivityChanges: changes.stream,
          child: const Scaffold(body: Text('Content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsOneWidget);

    changes.add([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Back online'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsNothing);
  });

  testWidgets('does not hide a new offline state on an old online timer', (
    tester,
  ) async {
    final changes = StreamController<List<ConnectivityResult>>();
    addTearDown(changes.close);

    await tester.pumpWidget(
      MaterialApp(
        home: NetworkBanner(
          checkConnectivity: () async => [ConnectivityResult.none],
          connectivityChanges: changes.stream,
          child: const Scaffold(body: Text('Content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    changes.add([ConnectivityResult.wifi]);
    await tester.pump();
    changes.add([ConnectivityResult.none]);
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('No internet connection'), findsOneWidget);
  });
}
