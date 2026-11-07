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
  final _codeFocus = FocusNode();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String? _phoneValidationError;
  String? _developmentCode;
  String? _submittedPhone;
  String? _status;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    _codeFocus.addListener(_refreshCodeBoxes);
  }

  void _refreshCodeBoxes() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    _code.dispose();
    _codeFocus.dispose();
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
      setState(() {
        _phoneValidationError = 'Enter a valid phone number with country code.';
        _error = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _phoneValidationError = null;
    });
    try {
      final code = await ref
          .read(phoneAuthRepositoryProvider)
          .requestCode(phone);
      if (mounted) {
        setState(() {
          _codeSent = true;
          _submittedPhone = phone;
          _status = resend ? 'New code sent to $phone' : 'Code sent to $phone';
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
    _codeFocus.unfocus();
    setState(() {
      _codeSent = false;
      _submittedPhone = null;
      _resendSeconds = 0;
      _status = null;
      _code.clear();
      _error = null;
      _phoneValidationError = null;
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
              const SizedBox(height: 28),
              Text(
                _codeSent ? 'Enter your code' : 'Sign in with phone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: VelaColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (_codeSent) ...[
                Text(
                  _status ?? 'Code sent to $_submittedPhone',
                  style: const TextStyle(color: VelaColors.plum),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _busy ? null : _changePhone,
                  style: TextButton.styleFrom(
                    foregroundColor: VelaColors.apricot,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Change number'),
                ),
              ] else
                const Text(
                  "We'll text you a 4-digit code.",
                  style: TextStyle(color: VelaColors.plum),
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
                  errorText: _phoneValidationError,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendCode(),
                  onChanged: (_) {
                    if (_error != null || _phoneValidationError != null) {
                      setState(() {
                        _error = null;
                        _phoneValidationError = null;
                      });
                    }
                  },
                )
              else
                _buildCodeBoxes(),
              if (_error != null || widget.startupError != null) ...[
                const SizedBox(height: 12),
                AppMessageBox(
                  message: _error ?? widget.startupError!,
                  kind: AppMessageKind.error,
                ),
              ],
              const SizedBox(height: 22),
              AppButton(
                label: _codeSent ? 'Verify code' : 'Send code',
                onPressed: _codeSent ? _verify : () => _sendCode(),
                isLoading: _busy,
                expanded: true,
              ),
              if (_codeSent) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _busy || _resendSeconds > 0
                        ? null
                        : () => _sendCode(resend: true),
                    style: TextButton.styleFrom(
                      foregroundColor: VelaColors.apricot,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      _resendSeconds > 0
                          ? 'Resend in ${_resendSeconds}s'
                          : 'Resend code',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBoxes() {
    final code = _code.text;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: '4-digit verification code',
                child: TextField(
                  controller: _code,
                  focusNode: _codeFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  autofocus: true,
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                  onChanged: (_) {
                    setState(() {
                      if (_error != null) _error = null;
                    });
                  },
                  onSubmitted: (_) => _verify(),
                ),
              ),
            ),
            IgnorePointer(
              child: ExcludeSemantics(
                child: Row(
                  children: List.generate(4, (index) {
                    final active =
                        _codeFocus.hasFocus &&
                        index == (code.length < 4 ? code.length : 3);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 3 ? 0 : 10),
                        child: Container(
                          key: ValueKey('otp-digit-$index'),
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: VelaColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? VelaColors.ink
                                  : const Color(0xFF8A6C7E),
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            index < code.length ? code[index] : '',
                            style: const TextStyle(
                              color: VelaColors.ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
