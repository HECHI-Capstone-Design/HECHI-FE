import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';

class GroupNotificationTile extends StatelessWidget {
  final NotificationItem item;

  const GroupNotificationTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool showSquareBook = item.type == 'GROUP_MISSION_UPDATE';

    return InkWell(
      onTap: () {
        // 1. 기존 기능: 알림 읽음 처리
        Get.find<NotificationController>().markAsRead(item.notificationId);

        print("📢 [그룹 알림 터치!] targetInfo: ${item.targetInfo}");

        try {
          dynamic info = item.targetInfo;

          if (info is String && info.startsWith('{')) {
            info = jsonDecode(info);
          }

          if (info is Map && info.containsKey('groupId')) {
            final groupIdValue = info['groupId'];
            final parsedGroupId = int.tryParse(groupIdValue.toString());

            // ✅ 여기를 실제 그룹 라우트 주소로 변경했습니다!
            if (parsedGroupId != null) {
              Get.toNamed('/group/main', arguments: {'groupId': parsedGroupId});
            } else {
              Get.toNamed('/group/main', arguments: {'groupId': groupIdValue.toString()});
            }
          } else {
            print("🚨 그룹 ID를 찾을 수 없습니다. info: $info");
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            showSquareBook && item.imageUrl != null
                ? _BookThumbnail(imageUrl: item.imageUrl!)
                : _GroupAvatar(imageUrl: item.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: kNotifGreen, fontSize: 13,
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                      Text(item.timeAgo, style: const TextStyle(color: kNotifTextGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '· ${item.description}',
                    style: const TextStyle(color: kNotifTextMid, fontSize: 13, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
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
  final String imageUrl;
  const _BookThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 48, height: 64, color: const Color(0xFFF3F3F3),
        child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book, color: kNotifBorder, size: 24)),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final String? imageUrl;
  const _GroupAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: kNotifGreenLight, shape: BoxShape.circle, border: Border.all(color: kNotifGreen.withOpacity(0.3), width: 1)),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: kNotifGreen, size: 26)))
          : const Icon(Icons.person, color: kNotifGreen, size: 26),
    );
  }
}