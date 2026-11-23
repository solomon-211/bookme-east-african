import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import 'widgets/auth_note.dart';
import 'widgets/otp_boxes.dart';

// "Check your messages." — enter the six-digit SMS code.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _resendSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  // A local countdown for the "Resend code" link only.
  Timer? _timer;
  int _remaining = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) t.cancel();
      if (mounted) setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(OtpSubmitted(_code.text.trim()));
  }

  void _resend(String phone) {
    context.read<AuthBloc>().add(PhoneNumberSubmitted(phone, isResend: true));
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final phone = context.select((AuthBloc b) => b.state.phoneNumber) ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Verify your number',
              subtitle: 'Secure sign in',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sms_outlined,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Check your messages.',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enter the six-digit code sent by SMS to '
                        '${Formatters.phone(phone)}.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OtpBoxes(
                        key: const Key('otp_field'),
                        controller: _code,
                        validator: Validators.otp,
                        onCompleted: (_) => _verify(),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _remaining > 0 ? null : () => _resend(phone),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: palette.link,
                          disabledForegroundColor: palette.link,
                        ),
                        child: Text(
                          _remaining > 0
                              ? 'Resend code in 0:'
                                    '${_remaining.toString().padLeft(2, '0')}'
                              : 'Resend code',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: palette.muted,
                        ),
                        child: const Text('Wrong number? Change phone number'),
                      ),
                      const SizedBox(height: 12),
                      const AuthNote(
                        icon: Icons.shield_outlined,
                        text:
                            'Keep this code private. BookMe support will never '
                            'ask you to share an OTP or your mobile money PIN.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: BlocBuilder<AuthBloc, AuthState>(
                buildWhen: (p, c) => p.isLoading != c.isLoading,
                builder: (context, state) => PrimaryButton(
                  key: const Key('verify_otp'),
                  label: 'Verify and Continue',
                  isLoading: state.isLoading,
                  onPressed: _verify,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
