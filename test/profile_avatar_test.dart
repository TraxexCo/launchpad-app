import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/widgets/profile_avatar.dart';

void main() {
  testWidgets('profile avatar shows initials and an accessible edit action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(
            size: 64,
            fallbackLabel: 'PR',
            showEditBadge: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('PR'), findsOneWidget);
    final editAction = find.bySemanticsLabel(RegExp('Change profile photo'));
    expect(editAction, findsOneWidget);
    await tester.tap(editAction);
    expect(tapped, isTrue);
    semantics.dispose();
  });
}
