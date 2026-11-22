import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';

/// Labelled text field in the BookMe style: small grey label above a white
/// rounded box, with the validation message shown underneath.
class BookingTextField extends StatelessWidget {
  const BookingTextField({
    required this.label,
    required this.controller,
    this.validator,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.fieldKey,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  /// Key on the inner `TextFormField`, used by widget tests.
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: fieldKey,
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: bookingInputDecoration(
              hint: hint,
              helper: helper,
              prefixIcon: prefixIcon,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration bookingInputDecoration({
  String? hint,
  String? helper,
  IconData? prefixIcon,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    errorMaxLines: 3,
    filled: true,
    fillColor: AppColors.card,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 20, color: AppColors.muted),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.ink),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error),
  );
}
