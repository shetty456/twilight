import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network/network.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';

class PhoneSignInPage extends ConsumerStatefulWidget {
  const PhoneSignInPage({super.key, this.startupError});
  final String? startupError;

  @override
  ConsumerState<PhoneSignInPage> createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends ConsumerState<PhoneSignInPage> {
  final _phone = TextEditingController(text: '+91 ');
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String? _developmentCode;
  String? _submittedPhone;
  String? _status;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final number = _phone.text.trim();
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (number.startsWith('+')) return '+$digits';
    return '+91$digits';
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSeconds = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (_busy || (resend && _resendSeconds > 0)) return;
    final phone = resend ? _submittedPhone : _normalizedPhone;
    if (phone == null || !RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a valid phone number with country code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref
          .read(phoneAuthRepositoryProvider)
          .requestCode(phone);
      if (mounted) {
        setState(() {
          _codeSent = true;
          _submittedPhone = phone;
          _status = resend
              ? 'A new code was sent to $phone.'
              : 'We sent a 4-digit code to $phone.';
          _code.clear();
          _developmentCode =
              ref.read(apiConfigProvider).environment.isDevelopment
              ? code
              : null;
          _startResendCooldown();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || !_codeSent || _submittedPhone == null) return;
    if (!RegExp(r'^\d{4}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the 4-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .verify(_submittedPhone!, _code.text.trim());
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^[^:]+: '), '');

  void _changePhone() {
    _resendTimer?.cancel();
    setState(() {
      _codeSent = false;
      _submittedPhone = null;
      _resendSeconds = 0;
      _status = null;
      _code.clear();
      _error = null;
      _developmentCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(productNameProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: VelaColors.blush,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      size: 26,
                      color: VelaColors.apricot,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: VelaColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Stories for a quieter moment.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: VelaColors.plum),
              ),
              const SizedBox(height: 28),
              Text(
                _codeSent ? 'Enter your code' : 'Sign in with phone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: VelaColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (_codeSent)
                Text(
                  _status ?? 'Enter the 4-digit code for $_submittedPhone.',
                  style: const TextStyle(color: VelaColors.plum),
                ),
              if (_codeSent && _developmentCode != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  'Development OTP: $_developmentCode',
                  style: const TextStyle(
                    color: VelaColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!_codeSent)
                AppTextField(
                  controller: _phone,
                  label: 'Phone number',
                  hint: '+91 98765 43210',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendCode(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                )
              else
                AppTextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  autofocus: true,
                  onSubmitted: (_) => _verify(),
                  label: 'Verification code',
                  hint: '0000',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              if (_error != null || widget.startupError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error ?? widget.startupError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (!_codeSent) ...[
                const SizedBox(height: 8),
                const Text(
                  'India +91 is prefilled. Replace it for another country.',
                  style: TextStyle(color: VelaColors.plum, fontSize: 13),
                ),
              ],
              const SizedBox(height: 22),
              AppButton(
                label: _codeSent ? 'Verify and continue' : 'Send code',
                onPressed: _codeSent ? _verify : () => _sendCode(),
                isLoading: _busy,
                expanded: true,
              ),
              if (_codeSent) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : _changePhone,
                      child: const Text('Change number'),
                    ),
                    TextButton(
                      onPressed: _busy || _resendSeconds > 0
                          ? null
                          : () => _sendCode(resend: true),
                      child: Text(
                        _resendSeconds > 0
                            ? 'Resend in ${_resendSeconds}s'
                            : 'Resend code',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
