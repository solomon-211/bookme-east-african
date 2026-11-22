import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';

// Six digit boxes backed by one hidden text field, so paste and SMS
// autofill still work. The next empty box is highlighted.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    required this.controller,
    this.validator,
    this.onCompleted,
    this.length = 6,
    super.key,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onCompleted;
  final int length;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _focus.requestFocus,
            child: Stack(
              children: [
                // Invisible field that really receives the typing.
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 56,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: widget.length,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) {
                        field.didChange(value);
                        if (value.length == widget.length) {
                          widget.onCompleted?.call(value);
                        }
                      },
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([widget.controller, _focus]),
                  builder: (context, _) {
                    final code = widget.controller.text;
                    // Capped so the boxes stay phone-sized in landscape.
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _Box(
                                digit: i < code.length ? code[i] : '',
                                active: _focus.hasFocus && i == code.length,
                                error: field.hasError,
                                palette: palette,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                field.errorText!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.digit,
    required this.active,
    required this.error,
    required this.palette,
  });

  final String digit;
  final bool active;
  final bool error;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final borderColor = error
        ? Theme.of(context).colorScheme.error
        : active
        ? palette.text
        : palette.border;

    return AspectRatio(
      aspectRatio: 0.85,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: active ? 2 : 1),
        ),
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: palette.text,
          ),
        ),
      ),
    );
  }
}
