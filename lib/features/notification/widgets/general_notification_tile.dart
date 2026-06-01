import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';
import 'package:hechi/app/routes.dart';

const Color kNotifGreen = Color(0xFF5C8C5A);
const Color kNotifGreenLight = Color(0xFFEAF3EA);
const Color kNotifBorder = Color(0xFFD4D4D4);
const Color kNotifTextDark = Color(0xFF3F3F3F);
const Color kNotifTextMid = Color(0xFF5F5F5F);
const Color kNotifTextGrey = Color(0xFF9E9E9E);

class GeneralNotificationTile extends StatelessWidget {
  final NotificationItem item;
  const GeneralNotificationTile({super.key, required this.item});

  // 🛠️ targetInfo를 안전하게 Map으로 파싱하는 헬퍼 함수
  Map<String, dynamic> _getParsedInfo() {
    try {
      dynamic info = item.targetInfo;
      if (info is String && info.startsWith('{')) {
        return jsonDecode(info);
      } else if (info is Map) {
        return Map<String, dynamic>.from(info);
      }
    } catch (e) {
      print("🚨 targetInfo 파싱 에러: $e");
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final info = _getParsedInfo(); // 파싱된 targetInfo

    return InkWell(
      onTap: () {
        // 1. 알림 읽음 처리
        Get.find<NotificationController>().markAsRead(item.notificationId);

        print("📢 [터치됨!] title: ${item.title}, targetInfo: $info");

        // 2. 🚀 routes.dart에 정의된 정확한 주소로 라우팅!
        if (info.containsKey('bookId')) {
          final parsedBookId = int.tryParse(info['bookId'].toString());
          if (parsedBookId != null) {
            // ✅ '/book_detail_page' 로 정확히 이동 (BookDetailController는 int 1개를 원함)
            Get.toNamed(Routes.bookDetailPage, arguments: parsedBookId);
          }
        }
        else if (info.containsKey('rewardId') || item.type == 'REWARD' || item.type == 'BADGE') {
          // ✅ '/reward' 로 정확히 이동 (RewardController는 파라미터를 받지 않으므로 비워둠)
          Get.toNamed(Routes.reward);
        }
        else if (info.containsKey('noticeId') || item.type == 'NOTICE') {
          // 🚨 현재 routes.dart에 공지사항 전용 페이지가 없으므로 임시로 고객센터로 연결
          print("🚨 공지사항 페이지 라우트가 routes.dart에 없습니다. 임시로 고객센터로 이동합니다.");
          Get.toNamed(Routes.customer);
        }
        else {
          print("🚨 이동할 수 있는 ID(bookId 등)가 targetInfo에 없습니다.");
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : kNotifGreenLight.withOpacity(0.5),
          border: const Border(bottom: BorderSide(width: 0.5, color: kNotifBorder)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. 🎨 내용물(Key)을 기준으로 썸네일 UI 분기 처리
            _buildThumbnail(info),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: kNotifTextDark, fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold, height: 1.3,
                          ),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(item.timeAgo, style: const TextStyle(color: kNotifTextGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(color: kNotifTextMid, fontSize: 12, height: 1.45),
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI 모양 분기 함수
  Widget _buildThumbnail(Map<String, dynamic> info) {
    if (info.containsKey('bookId') || item.title.contains('책')) {
      return _BookThumbnail(imageUrl: item.imageUrl);
    }
    else if (info.containsKey('rewardId') || item.type == 'REWARD') {
      return SizedBox(
        width: 60, height: 60,
        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(item.imageUrl!, fit: BoxFit.contain)
            : const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
      );
    }
    else {
      return _CircleThumbnail(imageUrl: item.imageUrl, type: item.type);
    }
  }
}

// 📚 책 표지 썸네일
class _BookThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _BookThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 60, height: 80, color: const Color(0xFFF3F3F3),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book, color: kNotifBorder, size: 28))
            : const Icon(Icons.book, color: kNotifBorder, size: 28),
      ),
    );
  }
}

// 🟢 동그라미 아이콘 위젯 (공지사항, 배지 등)
class _CircleThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String type;
  const _CircleThumbnail({this.imageUrl, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.notifications;
    if (type.contains('NOTICE')) icon = Icons.campaign;
    if (type.contains('BADGE')) icon = Icons.military_tech;

    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
          color: kNotifGreenLight,
          shape: BoxShape.circle,
          border: Border.all(color: kNotifGreen.withOpacity(0.3), width: 1)
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icon, color: kNotifGreen, size: 26)))
          : Icon(icon, color: kNotifGreen, size: 26),
    );
  }
}