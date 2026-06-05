import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/forget_password_controller.dart';
import '../../sign_up/widgets/sign_up_text_field.dart';
import 'instruction_banner.dart';
import 'forget_password_button.dart';

class StepTwoResetView extends StatelessWidget {
  final ForgetPasswordController controller;

  const StepTwoResetView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. 안내 배너
          const InstructionBanner(text: '새 비밀번호를 작성해주세요.'),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 2. 새 비밀번호 입력 (공개)
                SignUpTextField(
                  label: '새 비밀번호',
                  hintText: '영문, 숫자, 특수문자 조합(8자~20자)',
                  controller: controller.newPassController,
                  isObscure: false,
                ),
                const SizedBox(height: 20),

                // 3. 비밀번호 확인 입력 (숨김 토글)
                Obx(() => SignUpTextField(
                  label: '비밀번호 확인',
                  hintText: '비밀번호를 한번 더 입력해주세요.',
                  controller: controller.confirmPassController,
                  isObscure: controller.isConfirmHidden.value,
                  suffix: GestureDetector(
                    onTap: controller.toggleConfirmVisibility,
                    child: Icon(
                      controller.isConfirmHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMedium,
                    ),
                  ),
                )),

                const SizedBox(height: 40),

                // 4. 변경 버튼
                Obx(() => ForgetPasswordButton(
                  text: '비밀번호 변경하기',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.confirmPasswordReset,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}