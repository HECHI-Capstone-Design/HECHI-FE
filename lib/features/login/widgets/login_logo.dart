import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "HECHI",
        style: TextStyle(

          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}