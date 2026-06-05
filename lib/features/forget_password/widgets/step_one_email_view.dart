import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/forget_password_controller.dart';
import '../../sign_up/widgets/sign_up_text_field.dart'; // 기존 TextField 재사용
import 'instruction_banner.dart';
import 'forget_password_button.dart';

class StepOneEmailView extends StatelessWidget {
  final ForgetPasswordController controller;

  const StepOneEmailView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. 안내 배너
          const InstructionBanner(text: '기존에 가입한 이메일(아이디)을 입력해주세요.'),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 2. 이메일 입력창
                SignUpTextField(
                  label: '이메일',
                  hintText: '가입하신 이메일(아이디)을 작성해주세요.',
                  controller: controller.emailController,
                ),

                // 3. 에러 메시지
                Obx(() => controller.emailError.isEmpty
                    ? const SizedBox(height: 20)
                    : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 5, bottom: 15, left: 5),
                  child: Text(
                      controller.emailError.value,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)
                  ),
                )
                ),

                const SizedBox(height: 20),

                // 4. 확인 버튼
                Obx(() => ForgetPasswordButton(
                  text: '이메일(아이디) 확인하기',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.requestPasswordReset,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}