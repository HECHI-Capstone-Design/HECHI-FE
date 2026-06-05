import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sign_up_controller.dart';
import 'sign_up_text_field.dart';

class PasswordInputSection extends StatelessWidget {
  final SignUpController controller;

  const PasswordInputSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => SignUpTextField(
      label: '비밀번호',
      hintText: '영문, 숫자, 특수문자 조합(8자~20자)',
      controller: controller.passwordController,
      isObscure: controller.isPasswordHidden.value,
      suffix: Transform.translate(
        offset: const Offset(10, 0),
        child: GestureDetector(
          onTap: controller.togglePasswordVisibility,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              controller.isPasswordHidden.value
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMedium,
            ),
          ),
        ),
      ),
    ));
  }
}