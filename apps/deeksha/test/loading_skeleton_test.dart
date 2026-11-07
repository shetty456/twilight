import 'dart:async';

import 'package:deeksha/config/providers.dart';
import 'package:deeksha/data/origin_google_auth_repository.dart';
import 'package:deeksha/features/listener/listener_library.dart';
import 'package:deeksha/features/listener/listener_shell.dart';
import 'package:deeksha/features/listener/profile_page.dart';
import 'package:deeksha/features/stories/library_page.dart';
import 'package:deeksha/features/stories/search_page.dart';
import 'package:deeksha/features/stories/story_loading.dart';
import 'package:deeksha/stories/models/story_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';
import 'package:ui/ui.dart';

class _MemoryStorage implements StorageService {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('Startup uses the home skeleton and navigation layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ListenerShellLoading()));

    expect(find.byType(StoryHomeSkeleton), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    final heroSkeleton = tester.getSize(find.byType(AppSkeletonBox).first);
    expect(heroSkeleton.width / heroSkeleton.height, closeTo(5 / 6, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home and Search show layout skeletons while stories load', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stories = Completer<List<StorySeries>>();
    final overrides = [
      seriesProvider.overrideWith((ref) => stories.future),
      listenerLibraryProvider.overrideWith(
        (ref) => ListenerLibraryController(Future.value(_MemoryStorage())),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    expect(find.byType(StoryHomeSkeleton), findsOneWidget);
    final heroSkeleton = tester.getSize(find.byType(AppSkeletonBox).first);
    expect(heroSkeleton.width / heroSkeleton.height, closeTo(5 / 6, 0.001));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: SearchPage()),
      ),
    );
    expect(find.byType(StoryGridSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile shows library and count skeletons while loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = Completer<StorageService>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listenerLibraryProvider.overrideWith(
            (ref) => ListenerLibraryController(storage.future),
          ),
          signedInProfileProvider.overrideWith(
            (ref) async => const SignedInProfile(email: 'listener@example.com'),
          ),
        ],
        child: MaterialApp(home: ProfilePage(onExplore: () {})),
      ),
    );
    expect(find.byType(AppSkeletonBox), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('episode and audio placeholders fit a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [EpisodeListSkeleton(), AudioPlayerSkeleton()],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(AppSkeletonBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
