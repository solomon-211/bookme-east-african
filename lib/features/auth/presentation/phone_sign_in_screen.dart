import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/countries.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import 'widgets/auth_note.dart';

// "What's your phone number?" — the first step of phone sign-in.
class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  // Local choice for this form only; the number is sent to AuthBloc.
  Country _country = supportedCountries.first;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      PhoneNumberSubmitted(Validators.toE164(_country.dialCode, _phone.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return BlocListener<AuthBloc, AuthState>(
      // Move to the OTP screen once Firebase has sent the SMS code.
      listenWhen: (p, c) =>
          c.verificationId != null && p.verificationId != c.verificationId,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          context.push(AppRoutes.otp);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Sign in / Register',
                subtitle: 'One phone number. Every journey.',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "What's your phone number?",
                          style: TextStyle(
                            fontSize: 26,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your tickets, receipts and refunds are tied to '
                          "this number, so they're always yours.",
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: 22),
                        AuthFieldLabel('Country code'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in supportedCountries)
                              ChoicePill(
                                key: Key('country_${c.code}'),
                                label: '${c.code} ${c.dialCode}',
                                selected: c == _country,
                                onTap: () => setState(() => _country = c),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          key: const Key('phone_field'),
                          controller: _phone,
                          label: 'Phone number',
                          hint: '78 123 4412',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.telephoneNumberNational,
                          ],
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\s\-]'),
                            ),
                          ],
                          validator: Validators.localPhone,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We'll send a six-digit code by SMS. Standard SMS "
                          'rates may apply.',
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                        const SizedBox(height: 18),
                        const AuthNote(
                          icon: Icons.lock_outline,
                          text:
                              'BookMe will never ask for your MoMo PIN by call '
                              'or SMS. Only enter it on your own phone\'s '
                              'payment prompt.',
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "By continuing, you accept BookMe's Terms and "
                          "Privacy Policy. New here? We'll create your "
                          'account after verification.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: palette.muted,
                          ),
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
                    key: const Key('send_otp'),
                    label: 'Send OTP',
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
