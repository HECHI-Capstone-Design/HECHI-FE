import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sign_up_controller.dart';
import 'sign_up_text_field.dart';

class LoginIdInputSection extends StatelessWidget {
  final SignUpController controller;

  const LoginIdInputSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 아이디 입력창 & 중복확인 버튼
        Obx(() => SignUpTextField(
          label: '아이디 (Login ID)',
          hintText: '영문, 숫자 조합',
          controller: controller.loginIdController,
          suffix: Transform.translate(
            offset: const Offset(20, 0),
            child: GestureDetector(
              onTap: controller.checkLoginIdDuplicate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: controller.isLoginIdFilled.value
                      ? AppColors.primary
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                    '중복 확인',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
        )),

        // 2. 상태 메시지
        Obx(() {
          if (controller.isLoginIdAvailable.value == null) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              controller.loginIdStatusMessage.value,
              style: TextStyle(
                color: controller.isLoginIdAvailable.value!
                    ? AppColors.primary
                    : AppColors.error,
                fontSize: 12,
              ),
            ),
          );
        }),
      ],
    );
  }
}