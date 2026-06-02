import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 추가
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart'; // FCM 사용을 위해 추가
import 'package:hechi/app/routes.dart';
import 'package:hechi/app/controllers/app_controller.dart';
import '../../my_read/controllers/my_read_controller.dart';
import 'package:hechi/features/mainpage/controllers/mainpage_controller.dart';
import 'package:hechi/features/myGroup/controllers/my_group_controller.dart';

class LoginController extends GetxController {
  // ✅ emailController -> loginIdController 로 변경
  final loginIdController = TextEditingController();
  final passwordController = TextEditingController();

  RxBool isPasswordHidden = true.obs;
  RxBool isLoading = false.obs;
  RxBool isAutoLogin = false.obs;

  RxString loginIdError = ''.obs;
  RxString passwordError = ''.obs;

  final String baseUrl="https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loginIdController.addListener(() {
        if (loginIdError.isNotEmpty) loginIdError.value = '';
      });
      passwordController.addListener(() {
        if (passwordError.isNotEmpty) passwordError.value = '';
      });
    });
  }

  void togglePasswordVisibility() => isPasswordHidden.value = !isPasswordHidden.value;
  void toggleAutoLogin() => isAutoLogin.value = !isAutoLogin.value;

  Future<void> login() async {
    String loginId = loginIdController.text.trim();
    String password = passwordController.text.trim();

    if (loginId.isEmpty) {
      loginIdError.value = "아이디를 입력해주세요.";
      return;
    }
    if (password.isEmpty) {
      passwordError.value = "비밀번호를 입력해주세요.";
      return;
    }

    isLoading.value = true;

    try {
      final loginUrl = Uri.parse('$baseUrl/auth/login');
      final loginResponse = await http.post(
        loginUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "login_id": loginId, // ✅ "email" 대신 "login_id" 전송
          "password": password,
          "remember_me": isAutoLogin.value,
        }),
      );

      if (loginResponse.statusCode == 200) {
        final loginData = jsonDecode(utf8.decode(loginResponse.bodyBytes));

        await box.write('access_token', loginData['access_token']);
        await box.write('refresh_token', loginData['refresh_token']);
        await box.write('is_auto_login', isAutoLogin.value);
        await box.remove('is_taste_analyzed_local');

        debugPrint("✅ 로그인 성공");

        // ==============================================================
        // 🚀 [추가된 로직] 로그인 성공 직후 백엔드로 FCM 토큰 전송
        // ==============================================================
        try {
          String? fcmToken;
          if (kIsWeb) {
            fcmToken = await FirebaseMessaging.instance.getToken(
              vapidKey: 'BOr_TZ5oeMzEm0UWI5Vreqcu_cyNXaTXh_DT-_9QbFfUfHDxwvtlf99dW6VuRTtbiDlRltVJY3AcYvv7rZXc8R0',
            );
          } else {
            fcmToken = await FirebaseMessaging.instance.getToken();
          }

          if (fcmToken != null) {
            final pushUrl = Uri.parse('$baseUrl/notifications/register-token');
            final pushResponse = await http.post(
              pushUrl,
              headers: {
                "Content-Type": "application/json",
                // 로그인해서 받은 access_token을 넣어주므로 이제 403 에러가 나지 않습니다!
                "Authorization": "Bearer ${loginData['access_token']}"
              },
              body: jsonEncode({"fcm_token": fcmToken}),
            );

            if (pushResponse.statusCode == 200) {
              debugPrint("🚀 FCM 토큰 백엔드 등록 성공!");
            } else {
              debugPrint("❌ FCM 토큰 백엔드 등록 실패: ${pushResponse.statusCode}");
            }
          }
        } catch (fcmError) {
          debugPrint("❌ 로그인 후 FCM 전송 에러: $fcmError");
        }
        // ==============================================================

        final appController = Get.find<AppController>();
        await appController.fetchUserProfile();

        if (Get.isRegistered<MainpageController>()) {
          Get.delete<MainpageController>();
        }
        if (Get.isRegistered<MyGroupController>()) {
          Get.delete<MyGroupController>();
        }
        if (Get.isRegistered<MyReadController>()) {
          Get.delete<MyReadController>();
        }
        final profile = appController.userProfile;
        bool isAnalyzed = profile['taste_analyzed'] ?? false;

        if (isAnalyzed) {
          appController.changeIndex(0);
          Get.offAllNamed(Routes.initial);
        } else {
          Get.offAllNamed(Routes.preference);
        }

      } else if (loginResponse.statusCode == 403) {
        // ✅ 403 (이메일 미인증 상태) 처리 로직
        Get.snackbar(
          "알림", "이메일 인증이 완료되지 않은 계정입니다.\n인증을 진행해주세요.",
          backgroundColor: Colors.orange, colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        // 로그인 아이디를 들고 이메일 인증 화면으로 이동
        Get.toNamed(Routes.emailVerify, arguments: {'login_id': loginId});

      } else {
        passwordError.value = "아이디 혹은 비밀번호를 확인해주세요.";
      }
    } catch (e) {
      Get.snackbar("오류", "서버와 연결할 수 없습니다.", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void goToSignUp() => Get.toNamed(Routes.signUp);
  void goToForgetPassword() => Get.toNamed(Routes.forgetPassword);
}