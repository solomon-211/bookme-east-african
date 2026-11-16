import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/countries.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
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
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Enter your phone number',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    "We'll text you a 6-digit code to confirm it's you.",
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<Country>(
                    value: _country,
                    decoration: const InputDecoration(labelText: 'Country'),
                    items: [
                      for (final c in supportedCountries)
                        DropdownMenuItem(value: c, child: Text(c.toString())),
                    ],
                    onChanged: (c) => setState(() => _country = c ?? _country),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const Key('phone_field'),
                    controller: _phone,
                    label: 'Phone number',
                    hint: '788 123 456',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                    ],
                    validator: Validators.localPhone,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (p, c) => p.isLoading != c.isLoading,
                    builder: (context, state) => PrimaryButton(
                      label: 'Send code',
                      isLoading: state.isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
