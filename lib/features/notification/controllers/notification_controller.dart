import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/notification_item.dart';

class NotificationController extends GetxController {
  static const String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  var generalNotifications = <NotificationItem>[].obs;
  var groupNotifications = <NotificationItem>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshNotificationPage();
  }

  Future<void> refreshNotificationPage() async {
    await Future.wait([
      fetchNotifications(category: 'GENERAL'),
      fetchNotifications(category: 'GROUP'),
      fetchUnreadCount(),
    ]);
  }

  Map<String, String> _getHeaders() {
    String? token = box.read('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchNotifications({required String category}) async {
    try {
      isLoading.value = true;
      final url = Uri.parse('$baseUrl/users/me/notifications?tabCategory=$category&limit=40&offset=0');
      final response = await http.get(url, headers: _getHeaders());

      print("🔔 알림 API 응답 [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        print("🔔 파싱된 키 목록: ${decodedData.keys.toList()}");
        // 서버 응답 키가 notifications / items / content / data 등 다를 수 있음
        final List<dynamic> list = decodedData['notifications']
            ?? decodedData['items']
            ?? decodedData['content']
            ?? decodedData['data']
            ?? [];
        print("🔔 알림 개수: ${list.length}");
        List<NotificationItem> parsedList = list.map((json) => NotificationItem.fromJson(json)).toList();

        if (category == 'GENERAL') {
          generalNotifications.value = parsedList;
        } else {
          groupNotifications.value = parsedList;
        }
      } else {
        print("🔔 알림 API 실패: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("알림 목록 로드 실패: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final url = Uri.parse('$baseUrl/users/me/notifications/unread-count');
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        unreadCount.value = jsonDecode(response.body)['unreadCount'] ?? 0;
      }
    } catch (e) {}
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final token = box.read('access_token');
      if (token == null) return;
      // Swagger: GET /notifications/{notification_id}/read
      final url = Uri.parse('$baseUrl/notifications/$notificationId/read');
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        _updateLocalReadStatus(notificationId);
        fetchUnreadCount();
      }
    } catch (e) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final token = box.read('access_token');
      if (token == null) return;
      // Swagger: PATCH /notifications/read-all
      final url = Uri.parse('$baseUrl/notifications/read-all');
      final response = await http.patch(url, headers: _getHeaders());
      if (response.statusCode == 200) refreshNotificationPage();
    } catch (e) {}
  }

  Future<void> deleteAllNotifications() async {
    final token = box.read('access_token');
    if (token == null) {
      Get.snackbar("오류", "로그인이 필요합니다.");
      return;
    }
    try {
      isLoading.value = true;
      // Swagger: DELETE /notifications/all
      final url = Uri.parse('$baseUrl/notifications/all');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http.delete(url, headers: headers);

      print("📢 전체삭제 응답: ${response.statusCode} / ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        generalNotifications.clear();
        groupNotifications.clear();
        unreadCount.value = 0;
        Get.snackbar("성공", "모든 알림이 삭제되었습니다.");
      } else {
        print("🚨 전체삭제 응답 바디: ${response.body}");
        Get.snackbar("오류", "전체 삭제 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 전체 삭제 시스템 에러: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 개별 삭제 API 호출부 (ID 타입 체크 강화)
  Future<void> deleteNotification(dynamic notificationId) async {
    try {
      final token = box.read('access_token');
      if (token == null) return;
      final url = Uri.parse('$baseUrl/notifications/$notificationId');
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200 || response.statusCode == 204) {
        generalNotifications.removeWhere((item) => item.notificationId.toString() == notificationId.toString());
        groupNotifications.removeWhere((item) => item.notificationId.toString() == notificationId.toString());
        fetchUnreadCount();
      }
    } catch (e) {
      print("🚨 삭제 에러: $e");
    }
  }

  void _updateLocalReadStatus(int notificationId) {
    int genIndex = generalNotifications.indexWhere((item) => int.tryParse(item.notificationId.toString()) == notificationId);
    if (genIndex != -1) {
      generalNotifications[genIndex] = _cloneWithReadTrue(generalNotifications[genIndex]);
      return;
    }
    int grpIndex = groupNotifications.indexWhere((item) => int.tryParse(item.notificationId.toString()) == notificationId);
    if (grpIndex != -1) {
      groupNotifications[grpIndex] = _cloneWithReadTrue(groupNotifications[grpIndex]);
    }
  }

  NotificationItem _cloneWithReadTrue(NotificationItem item) {
    return NotificationItem(
      notificationId: item.notificationId, tabCategory: item.tabCategory, type: item.type,
      title: item.title, message: item.message, thumbnailUrl: item.thumbnailUrl,
      isRead: true, createdAt: item.createdAt, targetInfo: item.targetInfo,
    );
  }
}