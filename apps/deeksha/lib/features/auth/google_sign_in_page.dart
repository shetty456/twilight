import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app.dart';
import '../../config/product_config.dart';
import '../../config/providers.dart';

class GoogleSignInPage extends ConsumerStatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  ConsumerState<GoogleSignInPage> createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends ConsumerState<GoogleSignInPage> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).signInWithGoogle();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = kDebugMode
              ? 'Could not sign in with Google: $error'
              : 'Could not sign in with Google. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured =
        ProductConfig.googleServerClientId.isNotEmpty &&
        !kIsWeb &&
        (defaultTargetPlatform != TargetPlatform.iOS ||
            ProductConfig.googleIosClientId.isNotEmpty);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 28,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.asset(
                                'assets/branding/deeksha-app-icon-master.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          'Welcome to Deeksha',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: VelaColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Stories for a quieter moment. Sign in to keep yours close.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: VelaColors.plum,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const Spacer(),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: VelaColors.action),
                          ),
                          const SizedBox(height: 14),
                        ],
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            key: const ValueKey('google-sign-in'),
                            onPressed: _busy || !configured ? null : _signIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF202124),
                              disabledForegroundColor: const Color(0xFF5F6368),
                              disabledBackgroundColor: const Color(0xFFE7E2E7),
                              side: const BorderSide(color: Color(0xFFE2DCE2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : SvgPicture.asset(
                                    'assets/icons/google.svg',
                                    width: 22,
                                    height: 22,
                                  ),
                            label: Text(
                              _busy ? 'Signing in…' : 'Continue with Google',
                              style: TextStyle(
                                color: configured
                                    ? const Color(0xFF202124)
                                    : const Color(0xFF5F6368),
                              ),
                            ),
                          ),
                        ),
                        if (!configured) ...[
                          const SizedBox(height: 16),
                          const Text(
                            kIsWeb
                                ? 'Google sign-in is not yet available on the web.'
                                : 'Google sign-in is being configured.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: VelaColors.plum),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
