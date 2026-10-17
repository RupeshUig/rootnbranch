import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/// Standardized text input field for authentication forms.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final String? prefixText;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxLength;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.prefixText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.maxLength,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.white,
            hintText: widget.hintText,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.secondaryText.withValues(alpha: 0.65),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppColors.primaryPurple,
                    size: 20,
                  )
                : null,
            prefixText: widget.prefixText,
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.secondaryText,
                      size: 20,
                    ),
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                    onPressed: () {
                      setState(() {
                        _obscured = !_obscured;
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.subtleBorder,
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.subtleBorder,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryPurple,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.8),
            ),
            errorStyle: GoogleFonts.plusJakartaSans(
              color: AppColors.error,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
