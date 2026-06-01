import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hechi/app/main_app.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes.dart';
import 'app/bindings/app_binding.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔥 백그라운드 알림 수신: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await GetStorage.init();
  await setupFirebaseMessaging();
  runApp(const MyApp());
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
  print('✅ 알림 권한 상태: ${settings.authorizationStatus}');

  try {
    String? token;
    if (kIsWeb) {
      token = await messaging.getToken(
        vapidKey: 'BOr_TZ5oeMzEm0UWI5Vreqcu_cyNXaTXh_DT-_9QbFfUfHDxwvtlf99dW6VuRTtbiDlRltVJY3AcYvv7rZXc8R0',
      );
    } else {
      token = await messaging.getToken();
    }
    print('🔥 내 기기의 FCM 토큰: $token');

    if (token != null) await sendFcmTokenToBackend(token);
  } catch (e) {
    print('❌ FCM 토큰 발급 오류: $e');
  }

  messaging.onTokenRefresh.listen((newToken) {
    sendFcmTokenToBackend(newToken);
  });

  // ==============================================================
  // 🚀 [추가됨] 앱이 켜져 있을 때 (포그라운드) 푸시 수신 이벤트!
  // '오늘의 추천 도착' 알림이 여기서 화면에 표시됩니다.
  // ==============================================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔥 포그라운드 푸시 알림 수신: ${message.notification?.title}');

    if (message.notification != null) {
      Get.snackbar(
          message.notification!.title ?? '새로운 알림',
          message.notification!.body ?? '',
          backgroundColor: Colors.white,
          colorText: Colors.black,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.notifications_active, color: Color(0xFF4DB56C)),
          duration: const Duration(seconds: 4),
          boxShadows: [
            const BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)
          ]
      );
    }
  });
}

Future<void> sendFcmTokenToBackend(String fcmToken) async {
  const String baseUrl = "https://api.43-202-101-63.sslip.io";
  final url = Uri.parse('$baseUrl/notifications/register-token');
  final box = GetStorage();

  String? accessToken = box.read('access_token');

  // ✅ 추가
  if (accessToken == null || accessToken.isEmpty) {
    print("⚠️ 로그인 전 상태라 FCM 등록 생략");
    return;
  }

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "fcm_token": fcmToken,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ 백엔드에 FCM 토큰 등록 성공!");
    } else {
      print("❌ 백엔드 토큰 등록 실패: 상태코드 ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("❌ 백엔드 통신 에러: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HECHI App',
      theme: ThemeData(
        primaryColor: const Color(0xFF4DB56C),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      initialBinding: AppBinding(),
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
    );
  }
}