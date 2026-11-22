import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';

/// Email login and registration share one screen; a link toggles the mode.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.startInRegisterMode = false});

  final bool startInRegisterMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late bool _isLogin = !widget.startInRegisterMode;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _formKey.currentState?.reset();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bloc = context.read<AuthBloc>();
    if (_isLogin) {
      bloc.add(
        EmailSignInRequested(
          email: _email.text.trim(),
          password: _password.text,
        ),
      );
    } else {
      bloc.add(
        EmailRegisterRequested(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                  _isLogin ? 'Welcome back' : 'Create your account',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Log in to manage your trips and tickets.'
                      : 'Book seats and receive QR tickets on your phone.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                if (!_isLogin) ...[
                  AppTextField(
                    key: const Key('name_field'),
                    controller: _name,
                    label: 'Full name',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.fullName,
                  ),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  key: const Key('email_field'),
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  key: const Key('password_field'),
                  controller: _password,
                  label: 'Password',
                  obscure: true,
                  textInputAction: _isLogin
                      ? TextInputAction.done
                      : TextInputAction.next,
                  autofillHints: [
                    _isLogin
                        ? AutofillHints.password
                        : AutofillHints.newPassword,
                  ],
                  validator: _isLogin
                      ? Validators.passwordRequiredOnly
                      : Validators.newPassword,
                  onSubmitted: _isLogin ? (_) => _submit() : null,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const Key('confirm_field'),
                    controller: _confirm,
                    label: 'Confirm password',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    validator: Validators.confirmPassword(() => _password.text),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgot),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                const SizedBox(height: 16),
                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (p, c) => p.isLoading != c.isLoading,
                  builder: (context, state) => PrimaryButton(
                    key: const Key('submit_button'),
                    label: _isLogin ? 'Log in' : 'Create account',
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('toggle_mode'),
                  onPressed: _toggleMode,
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Register"
                        : 'Already have an account? Log in',
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
