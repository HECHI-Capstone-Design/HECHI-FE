import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class InstructionBanner extends StatelessWidget {
  final String text;

  const InstructionBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: AppColors.textHint,
      child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14)
      ),
    );
  }
}