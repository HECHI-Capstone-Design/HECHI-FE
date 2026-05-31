import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';

class GeneralNotificationTile extends StatelessWidget {
  final NotificationItem item;
  const GeneralNotificationTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // 1. 기존 기능: 알림 읽음 처리
        Get.find<NotificationController>().markAsRead(item.notificationId);

        print("📢 [일반 알림 터치!] targetInfo: ${item.targetInfo}");

        try {
          dynamic info = item.targetInfo;

          if (info is String && info.startsWith('{')) {
            info = jsonDecode(info);
          }

          if (info is Map) {
            if (info.containsKey('bookId')) {
              final parsedBookId = int.tryParse(info['bookId'].toString());
              if (parsedBookId != null) {
                // ✅ [핵심 수정] 딕셔너리(Map) 형태가 아니라 순수하게 '숫자(int)'만 넘겨줍니다!
                Get.toNamed('/book_detail_page', arguments: parsedBookId);
              }
            }
            else if (info.containsKey('badgeCode')) {
              print("📢 배지 획득 알림입니다! (이동할 경로가 있다면 여기에 추가하세요)");
            }
          }
        } catch (e) {
          print("🚨 라우팅 파싱 에러: $e");
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
            _BookThumbnail(imageUrl: item.imageUrl),
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
}

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