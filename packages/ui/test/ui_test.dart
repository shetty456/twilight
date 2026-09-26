import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  testWidgets('AppSkeleton enables automatic skeleton painting',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AppSkeleton(isLoading: true, child: Text('Loading content')),
      ),
    ));

    expect(
      tester
          .widget<Skeletonizer>(
            find.byWidgetPredicate((widget) => widget is Skeletonizer),
          )
          .enabled,
      isTrue,
    );
  });

  testWidgets('confirmation sheet returns the selected action', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () async {
                    result = await AppConfirmationSheet.show(
                      context,
                      title: 'Remove item?',
                      message: 'This cannot be undone.',
                      confirmLabel: 'Remove',
                      destructive: true,
                      warningMessage: 'Check before removing.',
                    );
                  },
                  child: const Text('Open'),
                )),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Check before removing.'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

String? _required(String? value) =>
    value == null || value.isEmpty ? 'Required' : null;
