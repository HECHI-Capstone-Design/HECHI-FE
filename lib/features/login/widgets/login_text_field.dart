import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? errorText; // 에러 메시지가 없으면 null 혹은 빈 문자열
  final bool obscureText;
  final TextInputType keyboardType;
  final VoidCallback? onToggleVisibility; // 비밀번호 눈 아이콘 클릭 시
  final bool isPassword; // 비밀번호 필드인지 여부 (아이콘 표시용)

  const LoginTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onToggleVisibility,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 라벨 (이메일, 비밀번호 등)
        Row(
          children: [
            const Text('* ', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. 입력창 컨테이너
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              // 비밀번호일 경우 눈 아이콘 표시
              if (isPassword)
                GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textMedium,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),

        // 3. 에러 메시지 (있을 때만 표시)
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 10),
            child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
}