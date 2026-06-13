import 'package:hechi/app/colors.dart';
import 'package:hechi/app/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hechi/app/main_app.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/routes.dart';
import 'app/bindings/app_binding.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';
import 'features/notification/controllers/notification_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// 🚀 [Final Best] 외부 푸시 알림 클릭 제어 (Internal 타일과 로직 통일)
void handleNotificationClick(RemoteMessage message) {
  debugPrint("📢 [External Push Click] Data: ${message.data}");
  if (message.data.isEmpty) return;

  try {
    Map<String, dynamic> info = {};
    final dynamic rawInfo = message.data['targetInfo'];

    // 1. 방어적 파싱
    if (rawInfo is String && rawInfo.startsWith('{')) {
      info = jsonDecode(rawInfo);
    } else if (rawInfo is Map) {
      info = Map<String, dynamic>.from(rawInfo);
    } else {
      info = message.data;
    }

    final String type = message.data['type']?.toString() ?? '';
    final String? reminderType = info['reminderType']?.toString();
    final String? groupId = info['groupId']?.toString();
    final String? bookId = info['bookId']?.toString();

    // 2. type 기반 우선 분기 + targetInfo 보조
    if (type == 'GROUP_JOIN' || type == 'GROUP_COMMENT' || type == 'GROUP_NOTICE') {
      // 그룹 관련 알림 → groupId 있으면 그룹 메인, 없으면 알림함
      if (groupId != null) {
        Get.toNamed(Routes.groupMain, arguments: groupId);
      } else {
        Get.toNamed(Routes.notification);
      }
    } else if (type == 'REVIEW_REACTION') {
      // 리뷰 좋아요 → bookId 있으면 책 상세, 없으면 알림함
      if (bookId != null) {
        final bId = int.tryParse(bookId);
        if (bId != null) {
          Get.toNamed(Routes.bookDetailPage, arguments: bId);
        } else {
          Get.toNamed(Routes.notification);
        }
      } else {
        Get.toNamed(Routes.notification);
      }
    // SLUMP/READING_REMINDER는 bookId보다 먼저 처리
    } else if (type.contains('SLUMP') || reminderType == 'READING_REMINDER') {
      Get.toNamed(Routes.bookStorage);
    } else if (groupId != null) {
      Get.toNamed(Routes.groupMain, arguments: groupId);
    } else if (bookId != null) {
      final bId = int.tryParse(bookId);
      if (bId != null) Get.toNamed(Routes.bookDetailPage, arguments: bId);
    } else if (info['badgeCode'] != null || info['rewardId'] != null || type.contains('REWARD')) {
      Get.toNamed(Routes.reward);
    } else if (info['noticeId'] != null || type.contains('NOTICE')) {
      Get.toNamed(Routes.customer);
    } else {
      Get.toNamed(Routes.notification);
    }
  } catch (e) {
    debugPrint("🚨 FCM Routing Error: $e");
    Get.toNamed(Routes.notification);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await GetStorage.init();
  await setupFirebaseMessaging();
  runApp(const MyApp());
}

Future<void> setupFirebaseMessaging() async {

  // 권한 요청 최적화
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  try {
    String? token = await messaging.getToken(
        vapidKey: kIsWeb ? 'BOr_TZ5oeMzEm0UWI5Vreqcu_cyNXaTXh_DT-_9QbFfUfHDxwvtlf99dW6VuRTtbiDlRltVJY3AcYvv7rZXc8R0' : null
    );
    if (token != null) await sendFcmTokenToBackend(token);
  } catch (e) {
    debugPrint('❌ FCM Token Error: $e');
  }

  // 토큰 갱신 리스너 유지
  messaging.onTokenRefresh.listen(sendFcmTokenToBackend);

  // 포그라운드 수신 (예쁜 스낵바 유지)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      // 포그라운드 알림 수신 시 뱃지 카운트 즉시 증가
      try {
        final notifController = Get.find<NotificationController>();
        notifController.unreadCount.value += 1;
      } catch (_) {}

      Get.snackbar(
          message.notification!.title ?? '새로운 알림',
          message.notification!.body ?? '',
          backgroundColor: Colors.white,
          colorText: Colors.black,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.notifications_active, color: AppColors.primary),
          duration: const Duration(seconds: 4),
          onTap: (snack) => handleNotificationClick(message),
          boxShadows: [const BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)]
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationClick);
  FirebaseMessaging.instance.getInitialMessage().then((msg) {
    if (msg != null) Future.delayed(const Duration(milliseconds: 1500), () => handleNotificationClick(msg));
  });
}

Future<void> sendFcmTokenToBackend(String fcmToken) async {
  final String baseUrl = AppConfig.baseUrl;
  final String? accessToken = GetStorage().read('access_token');
  if (accessToken == null || accessToken.isEmpty) return;
  try {
    await http.post(
      Uri.parse('$baseUrl/notifications/register-token'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({"fcm_token": fcmToken}),
    );
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
      // ✅ 추가: 키보드로 인한 리사이징 전역 설정
      builder: (context, child) {
        return MediaQuery(
          // 시스템 폰트 크기 변경해도 앱 레이아웃 안 깨지게
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
