import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'dart:io';
import '../routes.dart';
import '../../features/notification/controllers/notification_controller.dart';
import '../../features/review_detail/controllers/review_detail_controller.dart';
import '../../features/review_list/controllers/review_list_controller.dart';
import '../../features/groupcommunity/controllers/group_controller.dart';

class AppController extends GetxController {
  final box = GetStorage();
  final String baseUrl = "https://api.43-202-101-63.sslip.io";

  RxInt currentIndex = 0.obs;

  // 앱 전체에서 공유할 내 정보 변수
  final RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;

  // ✅ [수정] 기본 멘트로 초기화
  final RxString description = "나만의 소개글을 입력해주세요!".obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  // 내 정보 가져오기 (GET /auth/me)
  Future<void> fetchUserProfile() async {
    String? token = box.read('access_token');
    if (token == null) return;

    try {
      final response = await http.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: {"Authorization": "Bearer $token"}
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // 서버가 profileImageUrl을 누락했을 경우 기존 값을 보존
        final existingImageUrl = userProfile['profileImageUrl']?.toString() ?? '';
        userProfile.value = data;
        if ((userProfile['profileImageUrl'] == null || userProfile['profileImageUrl'].toString().isEmpty)
            && existingImageUrl.isNotEmpty) {
          userProfile['profileImageUrl'] = existingImageUrl;
        }

        String serverDesc = data['description'] ?? "";
        if (serverDesc.trim().isEmpty) {
          description.value = "나만의 소개글을 입력해주세요!";
        } else {
          description.value = serverDesc;
        }

        print("✅ 내 정보 로드 완료: ${userProfile['nickname']} / ${description.value}");
      }
    } catch (e) {
      print("Global Profile Error: $e");
    }
  }

  // 프로필 수정 요청 (PATCH /auth/me)
  Future<bool> updateUserProfile(String newNickname, String newDesc) async {
    String? token = box.read('access_token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/auth/me');

    try {
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "nickname": newNickname,
          "description": newDesc,
        }),
      );

      if (response.statusCode == 200) {
        // 성공 시 로컬 변수 갱신
        userProfile['nickname'] = newNickname;
        userProfile['description'] = newDesc;

        // ✅ [UI 갱신] 지우고 저장했으면 다시 기본 멘트로 돌아가게 설정
        if (newDesc.trim().isEmpty) {
          description.value = "나만의 소개글을 입력해주세요!";
        } else {
          description.value = newDesc;
        }

        userProfile.refresh();

        print("✅ 서버 프로필 업데이트 성공!");
        return true;
      } else {
        print("❌ 서버 업데이트 실패: ${response.statusCode}");
        Get.snackbar("오류", "저장에 실패했습니다.");
        return false;
      }
    } catch (e) {
      print("🚨 통신 오류: $e");
      Get.snackbar("오류", "서버와 연결할 수 없습니다.");
      return false;
    }
  }

  // 자동 로그인 체크
  Future<void> checkAutoLogin() async {
    print("🔄 앱 시작: 자동 로그인 여부 확인 중...");

    bool isAutoLoginEnabled = box.read('is_auto_login') ?? false;
    String? accessToken = box.read('access_token');

    if (!isAutoLoginEnabled || accessToken == null) {
      await Future.delayed(const Duration(milliseconds: 1000));
      Get.offAllNamed(Routes.login);
      return;
    }

    try {
      final meUrl = Uri.parse('$baseUrl/auth/me');
      final response = await http.get(
        meUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken"
        },
      );

      if (response.statusCode == 200) {
        print("✅ 자동 로그인 성공!");
        final meData = jsonDecode(utf8.decode(response.bodyBytes));
        final existingImageUrl = userProfile['profileImageUrl']?.toString() ?? '';
        userProfile.value = meData;
        if ((userProfile['profileImageUrl'] == null || userProfile['profileImageUrl'].toString().isEmpty)
            && existingImageUrl.isNotEmpty) {
          userProfile['profileImageUrl'] = existingImageUrl;
        }

        String serverDesc = meData['description'] ?? "";
        if (serverDesc.trim().isEmpty) {
          description.value = "나만의 소개글을 입력해주세요!";
        } else {
          description.value = serverDesc;
        }

        // 자동 로그인 시 FCM 토큰 등록
        _registerFcmToken(accessToken);

        // 로그인 성공 후 알림 카운트 갱신
        try {
          Get.find<NotificationController>().fetchUnreadCount();
        } catch (_) {}

        bool isAnalyzed = meData['taste_analyzed'] ?? false;
        if (isAnalyzed) {
          Get.offAllNamed(Routes.initial);
        } else {
          Get.offAllNamed(Routes.preference);
        }
      } else {
        box.write('is_auto_login', false);
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      Get.offAllNamed(Routes.login);
    }
  }

  // 프로필 이미지 업로드 (POST /users/me/profile-image)
  Future<bool> uploadProfileImage(File imageFile) async {
    String? token = box.read('access_token');
    if (token == null) return false;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/me/profile-image'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // 응답이 plain string("https://...") 또는 {"profileImageUrl":"..."} 두 형태 모두 처리
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final String? imageUrl = decoded is String
            ? decoded
            : decoded['profileImageUrl']?.toString();
        if (imageUrl == null || imageUrl.isEmpty) {
          print("❌ 프로필 이미지 URL 파싱 실패");
          return false;
        }
        userProfile['profileImageUrl'] = imageUrl;
        userProfile.refresh();
        print("✅ 프로필 이미지 업로드 성공: $imageUrl");

        // 현재 열려있는 컨트롤러의 데이터를 서버에서 재조회하여 최신 profileImageUrl 반영
        _refreshActiveControllers();

        return true;
      } else {
        print("❌ 프로필 이미지 업로드 실패: ${response.statusCode}");
        print("❌ 응답 바디: ${response.body}");
        Get.snackbar("오류", "이미지 업로드에 실패했습니다.");
        return false;
      }
    } catch (e) {
      print("🚨 이미지 업로드 오류: $e");
      Get.snackbar("오류", "서버와 연결할 수 없습니다.");
      return false;
    }
  }

  /// 프로필 이미지 변경 후 현재 등록된 컨트롤러들을 서버에서 재조회
  void _refreshActiveControllers() {
    if (Get.isRegistered<ReviewDetailController>()) {
      final c = Get.find<ReviewDetailController>();
      c.fetchReviewDetail();
      c.fetchComments();
    }
    if (Get.isRegistered<ReviewListController>()) {
      Get.find<ReviewListController>().fetchReviews();
    }
    if (Get.isRegistered<GroupController>()) {
      Get.find<GroupController>().fetchAllDataFromAPI();
    }
  }

  Future<void> _registerFcmToken(String accessToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await http.post(
        Uri.parse('$baseUrl/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({"fcm_token": fcmToken}),
      );
      print("🚀 자동 로그인 FCM 토큰 등록 완료");
    } catch (e) {
      print("❌ 자동 로그인 FCM 토큰 등록 실패: $e");
    }
  }
}