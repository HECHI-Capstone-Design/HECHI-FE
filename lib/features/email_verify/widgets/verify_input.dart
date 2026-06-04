import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class VerifyInput extends StatelessWidget {
  final TextEditingController controller;

  const VerifyInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, letterSpacing: 8.0, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: const TextStyle(color: AppColors.border),
        filled: true,
        fillColor: AppColors.divider,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}