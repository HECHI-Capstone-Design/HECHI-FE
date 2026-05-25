import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔥 백그라운드 알림 수신: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Storage를 먼저 초기화해야 토큰 전송 시 access_token을 읽을 수 있습니다.
  await GetStorage.init();

  await setupFirebaseMessaging();

  runApp(const MyApp());
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('✅ 알림 권한 상태: ${settings.authorizationStatus}');

  try {
    String? token = await messaging.getToken();
    print('====================================');
    print('🔥 내 기기의 FCM 토큰: $token');
    print('====================================');

    // ✅ 4. 발급된 토큰이 있으면 백엔드로 전송!
    if (token != null) {
      await sendFcmTokenToBackend(token);
    }
  } catch (e) {
    print('❌ FCM 토큰 발급 오류: $e');
  }

  // 앱 사용 중 토큰이 만료되어 갱신될 때도 백엔드에 다시 알려줍니다.
  messaging.onTokenRefresh.listen((newToken) {
    print('🔥 FCM 토큰 갱신됨: $newToken');
    sendFcmTokenToBackend(newToken);
  });
}

// ✅ 5. 백엔드에 FCM 토큰을 등록하는 함수 추가
Future<void> sendFcmTokenToBackend(String fcmToken) async {
  // 예전에 사용하셨던 서버 주소입니다. (필요시 변경하세요)
  const String baseUrl="https://api.43-202-101-63.sslip.io";
  final url = Uri.parse('$baseUrl/notifications/register-token');

  // 로그인된 유저인지 확인하기 위해 저장된 토큰을 꺼냅니다.
  final box = GetStorage();
  String? accessToken = box.read('access_token');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 백엔드에서 누구의 FCM 토큰인지 알아야 하므로 Authorization 헤더를 넣습니다.
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "fcm_token": fcmToken
      }),
    );

    if (response.statusCode == 200) {
      print("✅ 백엔드에 FCM 토큰 등록 성공!");
    } else {
      print("❌ 백엔드 토큰 등록 실패: 상태코드 ${response.statusCode}");
      print("응답 내용: ${utf8.decode(response.bodyBytes)}");
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
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      initialBinding: AppBinding(),
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
    );
  }
}