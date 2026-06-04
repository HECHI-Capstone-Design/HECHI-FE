import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hechi/app/routes.dart';

class SignUpController extends GetxController {
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  // ✅ 추가: 로그인 아이디 컨트롤러
  final loginIdController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RxBool isPasswordHidden = true.obs;
  // ✅ 이메일 대신 아이디 입력 여부 감지로 변경
  RxBool isLoginIdFilled = false.obs;

  // true: 사용가능, false: 중복/불가, null: 확인 안 함
  Rxn<bool> isLoginIdAvailable = Rxn<bool>();
  RxString loginIdStatusMessage = ''.obs;
  RxBool isLoading = false.obs;

  final String baseUrl="https://api.43-202-101-63.sslip.io";

  @override
  void onInit() {
    super.onInit();
    // ✅ 아이디 입력창 리스너 (글자가 바뀌면 중복확인 초기화)
    loginIdController.addListener(() {
      isLoginIdFilled.value = loginIdController.text.isNotEmpty;
      if (isLoginIdAvailable.value != null) {
        isLoginIdAvailable.value = null;
        loginIdStatusMessage.value = '';
      }
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    nicknameController.dispose();
    loginIdController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => isPasswordHidden.value = !isPasswordHidden.value;

  // ✅ 이메일 중복 확인 -> 아이디 중복 확인으로 변경
  Future<void> checkLoginIdDuplicate() async {
    if (!isLoginIdFilled.value) return;

    try {
      // ✅ API 엔드포인트 변경: /auth/login-id-check
      final url = Uri.parse('$baseUrl/auth/login-id-check?login_id=${loginIdController.text}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 서버 응답 구조에 맞춰 조정 (일반적으로 200이면 사용 가능, 아니면 400/409 에러)
        // 만약 서버가 { "available": true } 형태를 준다면 아래를 유지합니다.
        isLoginIdAvailable.value = true;
        loginIdStatusMessage.value = '사용 가능한 아이디입니다.';
      } else {
        isLoginIdAvailable.value = false;
        loginIdStatusMessage.value = '이미 사용 중인 아이디입니다.';
      }
    } catch(e) {
      debugPrint(e.toString());
      Get.snackbar("오류", "서버와 연결할 수 없습니다.", backgroundColor: Colors.black87, colorText: Colors.white);
    }
  }

  Future<void> submitSignUp() async {
    // 1. 기본 필드 입력 확인
    if (nameController.text.isEmpty ||
        nicknameController.text.isEmpty ||
        loginIdController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar("알림", "모든 필드를 입력해주세요.",
          backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    // 2. 아이디 중복 확인 여부 검사
    if (isLoginIdAvailable.value != true) {
      Get.snackbar("알림", "아이디 중복 확인을 먼저 완료해주세요.",
          backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    try {
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "login_id": loginIdController.text, // ✅ login_id 추가
          "email": emailController.text,
          "name": nameController.text,
          "nickname": nicknameController.text,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '회원가입 성공!',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Roboto'
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '환영합니다.\n이메일 인증을 진행해주세요.', // ✅ 텍스트 변경
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textDark, fontFamily: 'Roboto', height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () {
                      Get.back(); // 팝업 닫기
                      // ✅ 로그인 화면 대신 이메일 인증 화면으로 이동 (이메일 정보 전달)
                      Get.offAllNamed(Routes.emailVerify, arguments: {'email': emailController.text});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text(
                        '이메일 인증하러 가기', // ✅ 버튼 텍스트 변경
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );

      } else {
        Get.snackbar("가입 실패", "입력 정보를 확인해주세요. (${response.statusCode})",
            backgroundColor: Colors.black87, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("오류", "서버 연결 실패",
          backgroundColor: Colors.black87, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}