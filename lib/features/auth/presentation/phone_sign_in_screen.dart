import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/countries.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/control_style.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _phone = TextEditingController();
  Country _country = supportedCountries.first;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<Country>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in supportedCountries)
              ListTile(
                key: Key('country_${c.name}'),
                leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                title: Text(c.name),
                trailing: Text(c.dialCode,
                    style: const TextStyle(color: AppColors.muted)),
                selected: c == _country,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _country = picked);
  }

  void _submit() {
    final error = Validators.localPhone(_phone.text);
    setState(() => _error = error);
    if (error != null) return;
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Always one line: shrinks on narrow screens instead of wrapping.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Join us via phone number',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("We'll text a code to verify your phone",
                    style: TextStyle(fontSize: 15)),
                const SizedBox(height: 24),
                // Same width and height as the Next button below.
                SizedBox(
                  key: const Key('phone_field_box'),
                  width: double.infinity,
                  height: kControlHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(kControlRadius),
                      border: Border.all(
                        color: _error == null ? AppColors.ink : AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          InkWell(
                            key: const Key('country_picker'),
                            onTap: _pickCountry,
                            child: Row(
                              children: [
                                Text(_country.flag,
                                    style: const TextStyle(fontSize: 22)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_country.dialCode,
                              key: const Key('dial_code'),
                              style: const TextStyle(fontSize: 17)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              key: const Key('phone_field'),
                              controller: _phone,
                              autofocus: true,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(fontSize: 17),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d\s\-]')),
                              ],
                              decoration: const InputDecoration.collapsed(
                                  hintText: '788 123 456'),
                              onChanged: (_) {
                                if (_error != null) {
                                  setState(() => _error = null);
                                }
                              },
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(_error!,
                        key: const Key('phone_error'),
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                const Spacer(),
                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (p, c) => p.isLoading != c.isLoading,
                  builder: (context, state) => PrimaryButton(
                    key: const Key('phone_next'),
                    label: 'Next',
                    isLoading: state.isLoading,
                    onPressed: _submit,
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
