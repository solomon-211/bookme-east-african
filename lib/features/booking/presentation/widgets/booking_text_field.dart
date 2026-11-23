import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bookme_summative_project/core/theme/app_palette.dart';

/// Labelled text field in the BookMe style: small grey label above a
/// rounded card-coloured box, with the validation message underneath.
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
            ).textTheme.bodySmall?.copyWith(color: context.palette.muted),
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
            style: bookingInputTextStyle(context),
            cursorColor: context.palette.text,
            decoration: bookingInputDecoration(
              context,
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

/// What the traveller types: full-strength text colour, slightly bold, so
/// it never looks like the grey hint.
TextStyle bookingInputTextStyle(BuildContext context) => TextStyle(
  color: context.palette.text,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

InputDecoration bookingInputDecoration(
  BuildContext context, {
  String? hint,
  String? helper,
  IconData? prefixIcon,
}) {
  final palette = context.palette;
  // Theme error red: dark red in light mode, a lighter red in dark mode.
  final error = Theme.of(context).colorScheme.error;
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    // Lighter than typed text so an example is never mistaken for an answer.
    hintStyle: TextStyle(
      color: palette.muted.withValues(alpha: 0.6),
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    helperText: helper,
    helperStyle: TextStyle(color: palette.muted, fontSize: 12),
    errorStyle: TextStyle(
      color: error,
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
    ),
    helperMaxLines: 2,
    errorMaxLines: 3,
    filled: true,
    fillColor: palette.card,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 20, color: palette.muted),
    border: border(palette.border),
    enabledBorder: border(palette.border),
    focusedBorder: border(palette.text),
    errorBorder: border(error),
    focusedErrorBorder: border(error),
  );
}
