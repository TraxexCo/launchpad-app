import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad_app/widgets/app_text_field.dart';

void main() {
  testWidgets(
    'shared text fields expose their visible label to accessibility',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppTextField(label: 'Email')),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TextFormField));
      expect(semantics.label, 'Email');
    },
  );
}
