import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final String? prefixText;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixWidget,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixText,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        prefixText: widget.prefixText,
        prefixStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 20)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixWidget,
        counterText: '',
      ),
    );
  }
}
