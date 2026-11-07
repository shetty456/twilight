import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../stories/story_playback.dart';
import 'library_sections.dart';
import 'listener_library.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({
    super.key,
    required this.onExplore,
    this.profileCompletion,
  }) : assert(
         profileCompletion == null ||
             (profileCompletion >= 0 && profileCompletion <= 1),
       );

  final VoidCallback onExplore;
  final double? profileCompletion;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _busy = false;

  Future<void> _signOut() async {
    if (ref.read(listenerLibraryProvider).hasError) {
      AppSnackbar.show(
        context,
        'Open your library before signing out.',
        kind: AppMessageKind.error,
      );
      return;
    }
    final confirmed = await AppConfirmationSheet.show(
      context,
      title: 'Sign out?',
      message:
          'Your saved stories and listening history on this device will be cleared.',
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(storyPlaybackProvider).stop();
      await ref.read(listenerLibraryProvider.notifier).clear();
      await ref.read(sessionProvider.notifier).signOut();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Could not sign out. Please try again.',
          kind: AppMessageKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(listenerLibraryProvider);
    final library = libraryState.valueOrNull;
    final phoneState = ref.watch(signedInPhoneProvider);
    final savedCount = libraryState.isLoading || libraryState.hasError
        ? null
        : library?.saved.length ?? 0;
    final recentCount = libraryState.isLoading || libraryState.hasError
        ? null
        : library?.recent.length ?? 0;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            _ProfileHeader(
              savedCount: savedCount,
              recentCount: recentCount,
              phone: phoneState.valueOrNull,
              phoneLoading: phoneState.isLoading,
              libraryError: libraryState.hasError,
              completion: widget.profileCompletion,
            ),
            const SizedBox(height: 24),
            LibrarySections(onExplore: widget.onExplore),
            const Divider(height: 36, color: VelaColors.blush),
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: VelaColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _busy ? null : _signOut,
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: VelaColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(_busy ? 'Signing out…' : 'Sign out'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your library is stored on this device.',
              style: TextStyle(color: VelaColors.plum, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.savedCount,
    required this.recentCount,
    required this.phone,
    required this.phoneLoading,
    required this.libraryError,
    this.completion,
  });

  final int? savedCount;
  final int? recentCount;
  final String? phone;
  final bool phoneLoading;
  final bool libraryError;
  final double? completion;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
    decoration: BoxDecoration(
      color: VelaColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const CircleAvatar(
          radius: 46,
          backgroundColor: VelaColors.blush,
          child: Icon(
            Icons.person_rounded,
            color: VelaColors.apricot,
            size: 52,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: VelaColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        if (phoneLoading)
          const AppSkeletonLines(width: 174)
        else
          Text(
            phone ?? 'Phone number appears after your next sign-in',
            textAlign: TextAlign.center,
            style: const TextStyle(color: VelaColors.plum),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ProfileStat(
                count: savedCount,
                label: 'Series saved',
                unavailable: libraryError,
              ),
            ),
            Container(width: 1, height: 40, color: VelaColors.blush),
            Expanded(
              child: _ProfileStat(
                count: recentCount,
                label: 'Recent listens',
                unavailable: libraryError,
              ),
            ),
          ],
        ),
        if (completion != null) ...[
          const Divider(height: 36, color: VelaColors.blush),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Profile completion',
                  style: TextStyle(color: VelaColors.ink),
                ),
              ),
              Text(
                '${(completion! * 100).round()}%',
                style: const TextStyle(color: VelaColors.plum),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completion,
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: VelaColors.blush,
            color: VelaColors.apricot,
          ),
        ],
      ],
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.count,
    required this.label,
    required this.unavailable,
  });

  final int? count;
  final String label;
  final bool unavailable;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (unavailable)
        const Text('—', style: TextStyle(color: VelaColors.plum, fontSize: 20))
      else if (count == null)
        const AppSkeletonBox(width: 24, height: 26, radius: 5)
      else
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: VelaColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: VelaColors.plum, fontSize: 12)),
    ],
  );
}
