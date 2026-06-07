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
        final List<dynamic> list = decodedData['notifications']
            ?? decodedData['items']
            ?? decodedData['content']
            ?? decodedData['data']
            ?? [];
        List<NotificationItem> parsedList = list.map((json) => NotificationItem.fromJson(json)).toList();

        if (category == 'GENERAL') {
          generalNotifications.value = parsedList;
        } else {
          groupNotifications.value = parsedList;
        }
      } else {
        print("알림 API 실패: ${response.statusCode}");
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
      final url = Uri.parse('$baseUrl/notifications/read-all');
      final response = await http.patch(url, headers: _getHeaders());
      if (response.statusCode == 200) refreshNotificationPage();
    } catch (e) {}
  }

  /// 현재 탭 알림 전체 조회 후 병렬 삭제 (limit=500)
  Future<void> deleteAllByCategory(String category) async {
    final token = box.read('access_token');
    if (token == null) return;

    try {
      isLoading.value = true;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final fetchUrl = Uri.parse(
          '$baseUrl/users/me/notifications?tabCategory=$category&limit=500&offset=0');
      final fetchRes = await http.get(fetchUrl, headers: headers);

      List<int> allIds = [];
      if (fetchRes.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(fetchRes.bodyBytes));
        final List<dynamic> list = decoded['notifications']
            ?? decoded['items']
            ?? decoded['content']
            ?? decoded['data']
            ?? [];
        allIds = list.map<int>((n) => n['notificationId'] is int
            ? n['notificationId']
            : int.parse(n['notificationId'].toString())).toList();
        print("삭제 대상 $category: ${allIds.length}건");
      }

      if (allIds.isEmpty) {
        Get.snackbar("알림", "삭제할 알림이 없습니다.");
        return;
      }

      await Future.wait(allIds.map((id) async {
        final res = await http.delete(
          Uri.parse('$baseUrl/notifications/$id'),
          headers: {'Authorization': 'Bearer $token'},
        );
        print("삭제 [$id]: ${res.statusCode}");
      }));

      if (category == 'GENERAL') {
        generalNotifications.clear();
      } else {
        groupNotifications.clear();
      }
      await fetchUnreadCount();
      final label = category == 'GENERAL' ? '일반' : '그룹';
      Get.snackbar("완료", "$label 알림을 모두 삭제했습니다.");
    } catch (e) {
      print("전체삭제 에러: $e");
      Get.snackbar("오류", "삭제 중 오류가 발생했습니다.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNotification(dynamic notificationId) async {
    final idStr = notificationId.toString();
    try {
      final token = box.read('access_token');
      if (token == null) return;
      final url = Uri.parse('$baseUrl/notifications/$notificationId');
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200 || response.statusCode == 204) {
        generalNotifications.removeWhere((item) => item.notificationId.toString() == idStr);
        groupNotifications.removeWhere((item) => item.notificationId.toString() == idStr);
        fetchUnreadCount();
      }
    } catch (e) {
      print("삭제 에러: $e");
    }
  }

  void _updateLocalReadStatus(int notificationId) {
    int genIndex = generalNotifications.indexWhere(
        (item) => int.tryParse(item.notificationId.toString()) == notificationId);
    if (genIndex != -1) {
      generalNotifications[genIndex] = _cloneWithReadTrue(generalNotifications[genIndex]);
      return;
    }
    int grpIndex = groupNotifications.indexWhere(
        (item) => int.tryParse(item.notificationId.toString()) == notificationId);
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
