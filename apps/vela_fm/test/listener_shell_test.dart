import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';
import 'package:vela_fm/config/providers.dart';
import 'package:vela_fm/features/listener/listener_library.dart';
import 'package:vela_fm/features/listener/listener_shell.dart';
import 'package:vela_fm/stories/models/story_models.dart';

class _MemoryStorage implements StorageService {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

void main() {
  testWidgets('mobile navigation reaches Home, My Library, and Profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesProvider.overrideWith(
            (ref) async => const [
              StorySeries(id: 'one', title: 'Evening Stories'),
            ],
          ),
          listenerLibraryProvider.overrideWith(
            (ref) => ListenerLibraryController(Future.value(_MemoryStorage())),
          ),
        ],
        child: const MaterialApp(home: ListenerShell()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FEATURED STORY'), findsOneWidget);
    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('My Library').last);
    await tester.pumpAndSettle();
    expect(find.text('Your stories live here'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save to My Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Library').last);
    await tester.pumpAndSettle();
    expect(find.text('Saved series'), findsOneWidget);
    expect(find.text('Evening Stories'), findsOneWidget);
  });
}
