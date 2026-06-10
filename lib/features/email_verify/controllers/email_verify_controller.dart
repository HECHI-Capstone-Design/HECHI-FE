import 'package:hechi/app/colors.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../app/routes.dart';

class EmailVerifyController extends GetxController {
  final codeController = TextEditingController();
  final String baseUrl = AppConfig.baseUrl;

  var isLoading = false.obs;
  String targetEmail = "";

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('email')) {
      targetEmail = args['email'];
    }
  }

  Future<void> verifyEmail() async {
    if (codeController.text.trim().isEmpty) {
      Get.snackbar("알림", "인증 코드를 입력해주세요.");
      return;
    }
    if (targetEmail.isEmpty) {
      Get.snackbar("오류", "이메일 정보가 없습니다. 다시 로그인/가입을 시도해주세요.");
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": targetEmail,
          "code": codeController.text.trim()
        }),
      );

      if (response.statusCode == 200) {
        Get.offAllNamed(Routes.login);
        Get.snackbar("인증 완료", "이메일 인증이 완료되었습니다. 이제 로그인해주세요!",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("인증 실패", "인증 코드가 올바르지 않습니다.");
      }
    } catch (e) {
      Get.snackbar("오류", "서버와 연결할 수 없습니다.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode() async {
    if (targetEmail.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email/resend'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": targetEmail}),
      );

      if (response.statusCode == 200) {
        Get.snackbar("알림", "인증 코드가 재발송되었습니다.",
            backgroundColor: AppColors.primary, colorText: Colors.white);
      } else {
        Get.snackbar("오류", "재발송에 실패했습니다. (${response.statusCode})");
      }
    } catch (e) {
      Get.snackbar("오류", "서버 통신 실패");
    }
  }
}