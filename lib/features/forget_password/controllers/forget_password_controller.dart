import 'package:hechi/app/colors.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgetPasswordController extends GetxController {
  final emailController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  RxBool isEmailFilled = false.obs;
  RxString emailError = ''.obs;
  RxBool isNewPassFilled = false.obs;
  RxBool isConfirmPassFilled = false.obs;
  RxBool isConfirmHidden = true.obs; // ✅ 이 변수와 연결된 함수가 누락되었습니다.
  RxInt currentStep = 0.obs;
  RxBool isLoading = false.obs;

  final String baseUrl = AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() {
      isEmailFilled.value = emailController.text.isNotEmpty;
      if (emailError.isNotEmpty) emailError.value = '';
    });
    newPassController.addListener(() => isNewPassFilled.value = newPassController.text.isNotEmpty);
    confirmPassController.addListener(() => isConfirmPassFilled.value = confirmPassController.text.isNotEmpty);
  }

  @override
  void onClose() {
    emailController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.onClose();
  }

  // ✅ [추가/복구된 함수] 이 함수가 없어서 에러가 났던 겁니다.
  void toggleConfirmVisibility() => isConfirmHidden.value = !isConfirmHidden.value;

  // 1단계: 비밀번호 재설정 요청 (API 연동)
  Future<void> requestPasswordReset() async {
    String email = emailController.text;

    if (!GetUtils.isEmail(email)) {
      emailError.value = "이메일 형식이 올바르지 않습니다.";
      return;
    }

    isLoading.value = true;
    try {
      final checkUrl = Uri.parse('$baseUrl/auth/email-check?email=$email');
      final checkResponse = await http.get(checkUrl);

      if (checkResponse.statusCode == 200) {
        final data = jsonDecode(checkResponse.body);
        bool exists = data['exists'];

        if (exists) {
          // 재설정 요청 API 호출 (부수 효과)
          final requestUrl = Uri.parse('$baseUrl/auth/password-reset/request');
          await http.post(requestUrl, headers: {"Content-Type": "application/json"}, body: jsonEncode({"email": email}));

          currentStep.value = 1;
        } else {
          emailError.value = "가입되지 않은 이메일입니다.";
        }
      } else {
        emailError.value = "이메일 확인 중 오류가 발생했습니다.";
      }
    } catch (e) {
      Get.snackbar("오류", "서버 연결 실패", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white, colorText: Colors.black, borderColor: Colors.grey[300], borderWidth: 1);
    } finally {
      isLoading.value = false;
    }
  }

  // 2단계: 비밀번호 변경
  Future<void> confirmPasswordReset() async {
    if (newPassController.text.isEmpty || confirmPassController.text.isEmpty) return;

    if (newPassController.text != confirmPassController.text) {
      Get.snackbar("오류", "비밀번호가 일치하지 않습니다.", backgroundColor: Colors.white, colorText: AppColors.error, snackPosition: SnackPosition.BOTTOM, borderColor: Colors.grey[300], borderWidth: 1);
      return;
    }

    isLoading.value = true;
    try {
      final url = Uri.parse('$baseUrl/auth/password-reset/confirm');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "new_password": newPassController.text
        }),
      );

      if (response.statusCode == 200) {
        // 성공 팝업
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('비밀번호 변경 성공!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Roboto')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('비밀번호가 변경되었습니다.\n로그인을 진행해주세요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textDark, fontFamily: 'Roboto')),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                      Get.offAllNamed(Routes.login);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(25)),
                      alignment: Alignment.center,
                      child: const Text('로그인하러 가기', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
      } else {
        Get.snackbar("실패", "비밀번호 변경에 실패했습니다.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white, colorText: Colors.black, borderColor: Colors.grey[300], borderWidth: 1);
      }
    } catch (e) {
      Get.snackbar("오류", "서버 연결 실패", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white, colorText: Colors.black, borderColor: Colors.grey[300], borderWidth: 1);
    } finally {
      isLoading.value = false;
    }
  }
}