import 'package:flutter/material.dart';

class SignUpLogo extends StatelessWidget {
  const SignUpLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'HECHI',
      style: TextStyle(

        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4DB56C),
        letterSpacing: 0.25,
      ),
    );
  }
}