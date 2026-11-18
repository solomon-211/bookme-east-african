import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/account_validators.dart';
import '../domain/saved_passenger.dart';
import 'account_cubit.dart';
import 'account_state.dart';
import 'form_widgets.dart';

// Add a passenger (passenger == null) or edit an existing one.
Future<void> showPassengerForm(
  BuildContext context, {
  SavedPassenger? passenger,
}) {
  final cubit = context.read<AccountCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _PassengerForm(passenger: passenger),
    ),
  );
}

class _PassengerForm extends StatefulWidget {
  const _PassengerForm({this.passenger});

  final SavedPassenger? passenger;

  @override
  State<_PassengerForm> createState() => _PassengerFormState();
}

class _PassengerFormState extends State<_PassengerForm> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.passenger?.fullName);
  late final _phone = TextEditingController(
    text: widget.passenger?.phone ?? '+250',
  );
  late final _idNumber = TextEditingController(
    text: widget.passenger?.idNumber,
  );
  late final _nationality = TextEditingController(
    text: widget.passenger?.nationality ?? 'Rwanda',
  );

  bool get _isNew => widget.passenger == null;

  @override
  void dispose() {
    for (final c in [_name, _phone, _idNumber, _nationality]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final passenger = SavedPassenger(
      id: widget.passenger?.id ?? '',
      fullName: _name.text.trim(),
      phone: AccountValidators.normalisePhone(_phone.text),
      idNumber: _idNumber.text.replaceAll(' ', ''),
      nationality: _nationality.text.trim(),
    );

    final cubit = context.read<AccountCubit>();
    final ok = _isNew
        ? await cubit.addPassenger(passenger)
        : await cubit.updatePassenger(passenger);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: _isNew ? 'Add passenger' : 'Edit passenger',
      formKey: _formKey,
      children: [
        LabeledField(
          label: 'Full name · Must match their document',
          child: TextFormField(
            key: const Key('passenger_name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: AccountValidators.name,
          ),
        ),
        LabeledField(
          label: 'Phone · Ticket and travel alerts',
          child: TextFormField(
            key: const Key('passenger_phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: AccountValidators.phone,
          ),
        ),
        LabeledField(
          label: 'Passport / EAC ID number',
          child: TextFormField(
            key: const Key('passenger_id'),
            controller: _idNumber,
            validator: AccountValidators.idNumber,
          ),
        ),
        LabeledField(
          label: 'Nationality',
          child: TextFormField(
            key: const Key('passenger_nationality'),
            controller: _nationality,
            textCapitalization: TextCapitalization.words,
            validator: (v) => AccountValidators.required(v, 'the nationality'),
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<AccountCubit, AccountState>(
          buildWhen: (a, b) => a.saving != b.saving,
          builder: (context, state) => SaveButton(
            key: const Key('passenger_save'),
            label: _isNew ? 'Save passenger' : 'Save changes',
            saving: state.saving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
