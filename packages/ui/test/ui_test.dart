import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  test('app theme applies the same brand to light and dark schemes', () {
    const config = AppThemeConfig(primaryColor: Colors.teal);
    final light = AppTheme.light(config: config);
    final dark = AppTheme.dark(config: config);

    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.colorScheme.primary, isNot(equals(dark.colorScheme.primary)));
    expect(light.colorScheme.surface, isNot(equals(dark.colorScheme.surface)));
  });

  testWidgets('AppTextField participates in Form validation', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: key,
          child: const AppTextField(
            label: 'Name',
            validator: _required,
          ),
        ),
      ),
    ));

    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Ada');
    expect(key.currentState!.validate(), isTrue);
  });
}

String? _required(String? value) =>
    value == null || value.isEmpty ? 'Required' : null;
