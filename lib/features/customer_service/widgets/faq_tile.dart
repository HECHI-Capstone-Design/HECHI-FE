import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class FaqTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const FaqTile({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
    );
  }
}