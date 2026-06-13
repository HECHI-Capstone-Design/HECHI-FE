import 'package:flutter/material.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../routes.dart';
import '../../features/notification/controllers/notification_controller.dart';
import '../../features/review_detail/controllers/review_detail_controller.dart';
import '../../features/review_list/controllers/review_list_controller.dart';
import '../../features/groupcommunity/controllers/group_controller.dart';

class AppController extends GetxController {
  final box = GetStorage();
  final String baseUrl = AppConfig.baseUrl;

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

  // 로그아웃 시 호출: 다음 계정으로 정보가 누출되지 않도록 초기화
  void clearProfile() {
    userProfile.clear();
    description.value = "나만의 소개글을 입력해주세요!";
  }

  // 내 정보 가져오기 (GET /auth/me)
  Future<void> fetchUserProfile() async {
    String? token = box.read('access_token');
    if (token == null) return;

    try {
      var response = await http.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: {"Authorization": "Bearer $token"}
      );
      // 액세스 토큰 만료 시 리프레시 토큰으로 재발급 후 1회 재시도
      if (response.statusCode != 200) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          token = box.read('access_token');
          response = await http.get(
              Uri.parse('$baseUrl/auth/me'),
              headers: {"Authorization": "Bearer $token"}
          );
        }
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // 프로필은 서버 응답을 그대로 신뢰한다.
        // (이전 사용자 값을 보존하면 같은 기기에서 다른 계정으로 로그인 시 사진이 누출됨)
        userProfile.value = data;

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

  // 액세스 토큰 자동 재발급 (POST /auth/refresh)
  Future<bool> refreshAccessToken() async {
    final String? refreshToken = box.read('refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String? newAccess = data['access_token']?.toString();
        final String? newRefresh = data['refresh_token']?.toString();
        if (newAccess != null && newAccess.isNotEmpty) {
          await box.write('access_token', newAccess);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await box.write('refresh_token', newRefresh);
          }
          print("🔄 액세스 토큰 자동 재발급 성공");
          return true;
        }
      }
      print("❌ 토큰 재발급 실패: ${response.statusCode}");
      return false;
    } catch (e) {
      print("❌ 토큰 재발급 오류: $e");
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
      var response = await http.get(
        meUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken"
        },
      );

      // 액세스 토큰 만료 시 리프레시 토큰으로 재발급 후 1회 재시도
      if (response.statusCode != 200) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          accessToken = box.read('access_token');
          response = await http.get(
            meUrl,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $accessToken"
            },
          );
        }
      }

      if (response.statusCode == 200) {
        print("✅ 자동 로그인 성공!");
        final meData = jsonDecode(utf8.decode(response.bodyBytes));
        // 프로필은 서버 응답을 그대로 신뢰 (계정 간 사진 누출 방지)
        userProfile.value = meData;

        String serverDesc = meData['description'] ?? "";
        if (serverDesc.trim().isEmpty) {
          description.value = "나만의 소개글을 입력해주세요!";
        } else {
          description.value = serverDesc;
        }

        // 자동 로그인 시 FCM 토큰 등록 (재발급 됐을 수 있으니 최신 토큰 사용)
        final String? currentToken = box.read('access_token');
        if (currentToken != null) _registerFcmToken(currentToken);

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

  // 프로필 이미지 업로드 — 그룹 이미지와 동일한 presigned S3 흐름 사용 (웹 호환)
  // XFile을 받아 bytes로 읽으므로 dart:io File을 사용하지 않아 Flutter Web에서도 동작함
  Future<bool> uploadProfileImage(XFile pickedFile) async {
    String? token = box.read('access_token');
    if (token == null) return false;

    try {
      final bytes = await pickedFile.readAsBytes();
      final filename = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Step 1: presigned S3 URL 획득 (그룹 이미지와 동일한 엔드포인트)
      final presignRes = await http.post(
        Uri.parse('$baseUrl/uploads/presign?filename=$filename&contentType=image%2Fjpeg&acl=public-read'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (presignRes.statusCode != 200) {
        print("❌ presign 실패: ${presignRes.statusCode}");
        Get.snackbar("오류", "이미지 업로드에 실패했습니다.");
        return false;
      }

      final body = jsonDecode(utf8.decode(presignRes.bodyBytes)) as Map;
      String uploadUrl = body['url']?.toString() ?? body['presignedUrl']?.toString() ?? '';
      final String? presignPublicUrl = body['publicUrl']?.toString();
      final Map<String, String> fields = {};
      final rawFields = body['fields'];
      if (rawFields is Map) {
        rawFields.forEach((k, v) => fields[k.toString()] = v.toString());
      }

      if (uploadUrl.isEmpty) {
        print("❌ presign URL 비어있음");
        Get.snackbar("오류", "이미지 업로드에 실패했습니다.");
        return false;
      }

      // Step 2: S3에 직접 업로드 (fromBytes — 웹 호환)
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      fields.forEach((k, v) => request.fields[k] = v);
      request.files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final s3Res = await http.Response.fromStream(streamed);

      if (s3Res.statusCode != 200 && s3Res.statusCode != 201 && s3Res.statusCode != 204) {
        print("❌ S3 업로드 실패: ${s3Res.statusCode} / ${s3Res.body}");
        Get.snackbar("오류", "이미지 업로드에 실패했습니다.");
        return false;
      }

      // Step 3: 공개 URL 결정
      String? imageUrl;
      try {
        final decoded = jsonDecode(s3Res.body);
        if (decoded is Map) {
          imageUrl = (decoded['publicUrl'] ?? decoded['fileUrl'])?.toString();
        }
      } catch (_) {}
      imageUrl ??= presignPublicUrl;
      imageUrl ??= '${uploadUrl.endsWith('/') ? uploadUrl : '$uploadUrl/'}${fields['key'] ?? filename}';

      // Step 4: 백엔드에 최종 URL 저장 (PATCH /auth/me profileImageUrl 갱신)
      final patchRes = await http.patch(
        Uri.parse('$baseUrl/users/me/profile-image-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'profileImageUrl': imageUrl}),
      );

      if (patchRes.statusCode != 200) {
        // PATCH 전용 엔드포인트가 없을 경우 로컬 갱신만으로 처리
        print("⚠️ 서버 URL 갱신 실패 (${patchRes.statusCode}) — 로컬만 갱신");
      }

      userProfile['profileImageUrl'] = imageUrl;
      userProfile.refresh();
      print("✅ 프로필 이미지 업로드 성공 (S3): $imageUrl");
      _refreshActiveControllers();
      return true;
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