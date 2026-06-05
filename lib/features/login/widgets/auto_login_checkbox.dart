import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class AutoLoginCheckbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onTap;

  const AutoLoginCheckbox({
    super.key,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isChecked,
            onChanged: (value) => onTap(),
            activeColor: AppColors.primary,
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onTap,
          child: const Text("자동 로그인", style: TextStyle(color: Colors.black87, fontSize: 14)),
        ),
      ],
    );
  }
}