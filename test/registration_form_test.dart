import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/core/constants.dart';
import 'package:launchpad_app/screens/auth/register_screen.dart';
import 'package:launchpad_app/widgets/app_text_field.dart';

void main() {
  testWidgets('student registration blocks a five-character password inline',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: RegisterScreen(role: UserRole.student),
    ));
    await tester.pump(const Duration(milliseconds: 600));

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'Juan Perez');
    await tester.enterText(fields.at(1), 'juan@example.test');
    await tester.enterText(fields.at(2), '12345');
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.enterText(fields.at(2), 'P@ssw0rd123');
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is AppTextField &&
        widget.label == 'School', skipOffstage: false), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is AppTextField &&
        widget.label == 'Course', skipOffstage: false), findsOneWidget);
  });
}
