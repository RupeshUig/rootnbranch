import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/// 4-digit OTP entry field with focus management, paste support, and purple accent divider.
class OtpInputField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool hasError;

  const OtpInputField({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField> {
  static const int _otpLength = 4;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Exposes the current joined 4-character code.
  String get code => _controllers.map((c) => c.text).join();

  /// Clears all 4 OTP boxes and focuses the first digit.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
    widget.onChanged('');
  }

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste of multiple digits
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < _otpLength; i++) {
          if (i < digits.length) {
            _controllers[i].text = digits[i];
          }
        }
        final fullCode = code;
        widget.onChanged(fullCode);
        if (fullCode.length == _otpLength) {
          _focusNodes[_otpLength - 1].unfocus();
          widget.onCompleted?.call(fullCode);
        } else {
          _focusNodes[fullCode.length.clamp(0, _otpLength - 1)].requestFocus();
        }
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    final currentCode = code;
    widget.onChanged(currentCode);
    if (currentCode.length == _otpLength) {
      widget.onCompleted?.call(currentCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_otpLength, (index) {
            final isFocused = _focusNodes[index].hasFocus;
            final hasValue = _controllers[index].text.isNotEmpty;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              width: 56,
              height: 64,
              child: Semantics(
                label: 'Digit ${index + 1} of $_otpLength',
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) => _handleChanged(index, val),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: isFocused
                        ? AppColors.lightLavender.withValues(alpha: 0.15)
                        : AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? AppColors.error
                            : isFocused
                            ? AppColors.primaryPurple
                            : hasValue
                            ? AppColors.primaryPurple
                            : AppColors.subtleBorder,
                        width: isFocused ? 2.0 : 1.4,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? AppColors.error
                            : hasValue
                            ? AppColors.primaryPurple
                            : AppColors.subtleBorder,
                        width: 1.4,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primaryPurple,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        // Purple underline / divider beneath OTP boxes
        Container(
          width: 220,
          height: 2.5,
          decoration: BoxDecoration(
            color: widget.hasError
                ? AppColors.error.withValues(alpha: 0.5)
                : AppColors.primaryPurple.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
