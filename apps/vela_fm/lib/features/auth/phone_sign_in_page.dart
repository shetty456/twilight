import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../config/providers.dart';

class PhoneSignInPage extends ConsumerStatefulWidget {
  const PhoneSignInPage({super.key, this.startupError});
  final String? startupError;

  @override
  ConsumerState<PhoneSignInPage> createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends ConsumerState<PhoneSignInPage> {
  final _phone = TextEditingController(text: '+91');
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _validPhone => RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(_phone.text.trim());

  Future<void> _sendCode() async {
    if (!_validPhone) {
      setState(() => _error = 'Enter a phone number with country code, such as +919876543210.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(phoneAuthRepositoryProvider).requestCode(_phone.text.trim());
      if (mounted) setState(() => _codeSent = true);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{4}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the 4-digit code.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(sessionProvider.notifier).verify(_phone.text.trim(), _code.text.trim());
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) => error.toString().replaceFirst(RegExp(r'^[^:]+: '), '');

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(productNameProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: VelaColors.blush,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                child: const Icon(Icons.spa_outlined, size: 34, color: VelaColors.plum),
              ),
              const SizedBox(height: 38),
              Text(name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: VelaColors.ink, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 10),
              Text('A gentle place for stories, rest, and the moments in between.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: VelaColors.plum, height: 1.5,
                ),
              ),
              const SizedBox(height: 52),
              Text(_codeSent ? 'Enter your code' : 'Continue with your phone',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: VelaColors.ink, fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (_codeSent)
                Text('We sent a 4-digit code to ${_phone.text.trim()}.',
                  style: const TextStyle(color: VelaColors.plum)),
              const SizedBox(height: 18),
              if (!_codeSent)
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+919876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                )
              else
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  onSubmitted: (_) => _verify(),
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    hintText: '0000',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              if (_error != null || widget.startupError != null) ...[
                const SizedBox(height: 12),
                Text(_error ?? widget.startupError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _busy ? null : _codeSent ? _verify : _sendCode,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_codeSent ? 'Verify and continue' : 'Send code'),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                Center(child: TextButton(
                  onPressed: _busy ? null : () => setState(() {
                    _codeSent = false;
                    _code.clear();
                    _error = null;
                  }),
                  child: const Text('Change phone number'),
                )),
                Center(child: TextButton(
                  onPressed: _busy ? null : _sendCode,
                  child: const Text('Resend code'),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
