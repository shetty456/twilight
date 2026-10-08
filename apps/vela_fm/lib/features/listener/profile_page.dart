import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import 'listener_library.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _busy = false;

  Future<void> _signOut() async {
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
    final library = ref.watch(listenerLibraryProvider).valueOrNull;
    final savedCount = library?.saved.length ?? 0;
    final recentCount = library?.recent.length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: VelaColors.blush,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: VelaColors.plum,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Your listening space',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: VelaColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$savedCount saved series · '
                  '$recentCount recent ${recentCount == 1 ? 'listen' : 'listens'}',
                  style: const TextStyle(color: VelaColors.plum),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: VelaColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: VelaColors.plum),
              title: const Text('Sign out'),
              trailing: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: _busy ? null : _signOut,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your library is stored on this device.',
            style: TextStyle(color: VelaColors.plum, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
