import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _resendSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
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
      if (_remaining <= 1) {
        t.cancel();
      }
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
    final phone = context.select((AuthBloc b) => b.state.phoneNumber) ?? '';
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Verify your number',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to $phone',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  key: const Key('otp_field'),
                  controller: _code,
                  label: '6-digit code',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.otp,
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (p, c) => p.isLoading != c.isLoading,
                  builder: (context, state) => PrimaryButton(
                    label: 'Verify',
                    isLoading: state.isLoading,
                    onPressed: _verify,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _remaining > 0 ? null : () => _resend(phone),
                  child: Text(
                    _remaining > 0
                        ? 'Resend code in ${_remaining}s'
                        : 'Resend code',
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
