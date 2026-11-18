import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/account_validators.dart';
import '../domain/user_profile.dart';
import 'account_cubit.dart';
import 'account_state.dart';
import 'form_widgets.dart';

// One form for name, email, travel document and mobile money. The profile
// card, "IDs & passports" and "Mobile money numbers" all open it.
Future<void> showEditProfileSheet(BuildContext context, UserProfile profile) {
  final cubit = context.read<AccountCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _EditProfileForm(profile: profile),
    ),
  );
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({required this.profile});

  final UserProfile profile;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _email = TextEditingController(text: widget.profile.email);
  late final _idCountry = TextEditingController(
    text: widget.profile.idDocument?.country ?? 'Rwanda',
  );
  late final _idNumber = TextEditingController(
    text: widget.profile.idDocument?.number,
  );
  late final _momoPhone = TextEditingController(
    text: widget.profile.mobileMoney?.phone ?? widget.profile.phone,
  );
  late String _idType = widget.profile.idDocument?.type ?? 'EAC ID';
  late String _momoProvider =
      widget.profile.mobileMoney?.provider ?? 'MTN MoMo';

  @override
  void dispose() {
    for (final c in [_name, _email, _idCountry, _idNumber, _momoPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _email.text.trim();
    final updated = widget.profile.copyWith(
      fullName: _name.text.trim(),
      email: email.isEmpty ? null : email,
      idDocument: IdDocument(
        type: _idType,
        country: _idCountry.text.trim(),
        number: _idNumber.text.replaceAll(' ', ''),
      ),
      mobileMoney: MobileMoneyAccount(
        provider: _momoProvider,
        phone: AccountValidators.normalisePhone(_momoPhone.text),
      ),
    );

    final ok = await context.read<AccountCubit>().updateProfile(updated);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Edit profile',
      formKey: _formKey,
      children: [
        LabeledField(
          label: 'Full name · Must match your document',
          child: TextFormField(
            key: const Key('profile_name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            validator: AccountValidators.name,
          ),
        ),
        LabeledField(
          label: 'Email · Receipt copy (optional)',
          child: TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: AccountValidators.email,
          ),
        ),
        const FormSectionTitle('ID or passport'),
        LabeledField(
          label: 'Document type',
          child: DropdownButtonFormField<String>(
            initialValue: _idType,
            items: [
              for (final t in IdDocument.types)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _idType = v ?? _idType),
          ),
        ),
        LabeledField(
          label: 'Issuing country',
          child: TextFormField(
            controller: _idCountry,
            textCapitalization: TextCapitalization.words,
            validator: (v) => AccountValidators.required(v, 'the country'),
          ),
        ),
        LabeledField(
          label: 'Document number · Only shared with your operator',
          child: TextFormField(
            key: const Key('profile_id_number'),
            controller: _idNumber,
            validator: AccountValidators.idNumber,
          ),
        ),
        const FormSectionTitle('Mobile money'),
        LabeledField(
          label: 'Provider',
          child: DropdownButtonFormField<String>(
            initialValue: _momoProvider,
            items: [
              for (final p in MobileMoneyAccount.providers)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) =>
                setState(() => _momoProvider = v ?? _momoProvider),
          ),
        ),
        LabeledField(
          label: 'Mobile money number',
          child: TextFormField(
            controller: _momoPhone,
            keyboardType: TextInputType.phone,
            validator: AccountValidators.phone,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<AccountCubit, AccountState>(
          buildWhen: (a, b) => a.saving != b.saving,
          builder: (context, state) => SaveButton(
            key: const Key('profile_save'),
            saving: state.saving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
