import 'dart:convert';
import 'package:hechi/app/config/app_config.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class NotificationSettingsController extends GetxController {
  static final String baseUrl = AppConfig.baseUrl;
  final box = GetStorage();

  // 토글 스위치 상태를 관리할 반응형 변수들
  var pushEnabled = true.obs;
  var generalEnabled = true.obs;
  var groupEnabled = true.obs;
  var marketingEnabled = true.obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotificationSettings();
  }

  // API 헤더 세팅
  Map<String, String> _getHeaders() {
    String? token = box.read('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1️⃣ 기존 알림 설정 불러오기 (GET)
  Future<void> fetchNotificationSettings() async {
    try {
      isLoading.value = true;
      final url = Uri.parse('$baseUrl/users/me/notification-settings');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        pushEnabled.value = data['pushEnabled'] ?? true;
        generalEnabled.value = data['generalEnabled'] ?? true;
        groupEnabled.value = data['groupEnabled'] ?? true;
        marketingEnabled.value = data['marketingEnabled'] ?? true;
      }
    } catch (e) {
      print("🚨 알림 설정 로드 실패: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 2️⃣ 알림 설정 변경 서버에 저장하기 (PATCH)
  Future<void> updateSettings({
    bool? push,
    bool? general,
    bool? group,
    bool? marketing,
  }) async {
    // UI 스위치는 먼저 즉각적으로 바뀐 상태로 보여줌 (사용자 경험 향상)
    if (push != null) pushEnabled.value = push;
    if (general != null) generalEnabled.value = general;
    if (group != null) groupEnabled.value = group;
    if (marketing != null) marketingEnabled.value = marketing;

    try {
      final url = Uri.parse('$baseUrl/users/me/notification-settings');
      final body = jsonEncode({
        "pushEnabled": pushEnabled.value,
        "generalEnabled": generalEnabled.value,
        "groupEnabled": groupEnabled.value,
        "marketingEnabled": marketingEnabled.value,
      });

      final response = await http.patch(url, headers: _getHeaders(), body: body);

      if (response.statusCode != 200) {
        // 실패하면 원래대로 되돌리는 로직을 넣을 수도 있지만, 일단 에러 로그만 띄웁니다.
        print("❌ 알림 설정 변경 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 알림 설정 업데이트 에러: $e");
    }
  }
}