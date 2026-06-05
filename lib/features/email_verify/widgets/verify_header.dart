import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class VerifyHeader extends StatelessWidget {
  final String targetEmail;

  const VerifyHeader({
    super.key,
    required this.targetEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          '${targetEmail.isNotEmpty ? targetEmail : "입력하신 이메일"}으로\n인증 코드가 발송되었습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5),
        ),
        const SizedBox(height: 10),
        const Text(
          '이메일을 확인하고 6자리 인증 코드를 입력해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}