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

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = decodedData['notifications'] ?? [];
        List<NotificationItem> parsedList = list.map((json) => NotificationItem.fromJson(json)).toList();

        if (category == 'GENERAL') {
          generalNotifications.value = parsedList;
        } else {
          groupNotifications.value = parsedList;
        }
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
      final url = Uri.parse('$baseUrl/notifications/$notificationId/read');
      final response = await http.patch(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        _updateLocalReadStatus(notificationId);
        fetchUnreadCount();
      }
    } catch (e) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final url = Uri.parse('$baseUrl/notifications/read-all');
      final response = await http.patch(url, headers: _getHeaders());
      if (response.statusCode == 200) refreshNotificationPage();
    } catch (e) {}
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$notificationId');
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        generalNotifications.removeWhere((item) => item.notificationId == notificationId);
        groupNotifications.removeWhere((item) => item.notificationId == notificationId);
        fetchUnreadCount();
      }
    } catch (e) {}
  }

  Future<void> deleteAllNotifications() async {
    try {
      final url = Uri.parse('$baseUrl/notifications/all');
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        generalNotifications.clear();
        groupNotifications.clear();
        unreadCount.value = 0;
      }
    } catch (e) {}
  }

  void _updateLocalReadStatus(int notificationId) {
    int genIndex = generalNotifications.indexWhere((item) => item.notificationId == notificationId);
    if (genIndex != -1) {
      generalNotifications[genIndex] = _cloneWithReadTrue(generalNotifications[genIndex]);
      return;
    }
    int grpIndex = groupNotifications.indexWhere((item) => item.notificationId == notificationId);
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