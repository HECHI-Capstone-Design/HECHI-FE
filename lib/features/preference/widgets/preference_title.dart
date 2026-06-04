import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class PreferenceTitle extends StatelessWidget {
  final String highlight;
  final String subText;

  const PreferenceTitle({
    super.key,
    required this.highlight,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '내가 좋아하는 ', style: TextStyle(color: Colors.black, fontSize: 20)),
              TextSpan(
                text: highlight,
                style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '는?', style: TextStyle(color: Colors.black, fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}