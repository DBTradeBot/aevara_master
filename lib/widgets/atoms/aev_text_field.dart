import 'package:flutter/material.dart';

class AevTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hint;
  final String? Function(String?)? validator;

  const AevTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.prefixIcon,
    this.suffixIcon,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
