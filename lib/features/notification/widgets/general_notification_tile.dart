import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';
import 'package:hechi/app/routes.dart';

// UI 상단 공통 색상 상수 (기본 유지)
const Color kNotifGreen = Color(0xFF5C8C5A);
const Color kNotifGreenLight = Color(0xFFEAF3EA);
const Color kNotifBorder = Color(0xFFD4D4D4);
const Color kNotifTextDark = Color(0xFF3F3F3F);
const Color kNotifTextMid = Color(0xFF5F5F5F);
const Color kNotifTextGrey = Color(0xFF9E9E9E);

class GeneralNotificationTile extends StatelessWidget {
  final NotificationItem item;
  const GeneralNotificationTile({super.key, required this.item});

  Map<String, dynamic> _getParsedInfo() {
    try {
      dynamic info = item.targetInfo;
      if (info is String && info.startsWith('{')) return jsonDecode(info);
      if (info is Map) return Map<String, dynamic>.from(info);
    } catch (_) {}
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final info = _getParsedInfo();
    final String? reminderType = info['reminderType']?.toString();

    return InkWell(
      onTap: () {
        // 1. 읽음 처리
        Get.find<NotificationController>().markAsRead(item.notificationId);

        // 2. 🚀 [Final Best] 내부 타일 클릭 라우팅 (Push 로직과 100% 동기화 및 뱃지 복구)
        if (info['groupId'] != null) {
          Get.toNamed(Routes.groupMain, arguments: info['groupId'].toString());
        } else if (info['bookId'] != null) {
          Get.toNamed(Routes.bookDetailPage, arguments: int.tryParse(info['bookId'].toString()));
        } else if (info['badgeCode'] != null || info['rewardId'] != null || item.type.contains('REWARD') || item.type.contains('BADGE')) {
          Get.toNamed(Routes.reward);
        } else if (reminderType == 'READING_REMINDER' || item.type.contains('SLUMP')) {
          Get.toNamed(Routes.bookStorage);
        } else if (info['noticeId'] != null || item.type.contains('NOTICE')) {
          Get.toNamed(Routes.customer);
        } else {
          Get.toNamed(Routes.notification);
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
            _buildThumbnail(info),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.title, style: TextStyle(color: kNotifTextDark, fontSize: 14, fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold)),
                      ),
                      Text(item.timeAgo, style: const TextStyle(color: kNotifTextGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.description, style: const TextStyle(color: kNotifTextMid, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 썸네일 렌더링 로직 (슬럼프, 리워드, 책 표지, 아이콘 완벽 보존)
  Widget _buildThumbnail(Map<String, dynamic> info) {
    final String? resolvedUrl = item.imageUrl?.isNotEmpty == true ? item.imageUrl : (info['thumbnailUrl'] ?? info['imageUrl'])?.toString();
    final String? reminderType = info['reminderType']?.toString();

    if (item.type.contains('SLUMP') || (reminderType?.contains('SLUMP') ?? false)) return const _CheerThumbnail();

    // 🌟 별 모양 복구: badgeCode와 BADGE 타입 추가
    if (info['rewardId'] != null || info['badgeCode'] != null || item.type.contains('REWARD') || item.type.contains('BADGE')) return _RewardThumbnail(imageUrl: resolvedUrl);

    if (info['bookId'] != null) return _BookThumbnail(imageUrl: resolvedUrl);

    return _CircleThumbnail(
      imageUrl: resolvedUrl,
      type: item.type,
      reminderType: reminderType,
    );
  }
}

// (이하 _CheerThumbnail, _BookThumbnail, _RewardThumbnail, _CircleThumbnail은 기존의 예쁜 UI 코드 그대로 유지)

class _CheerThumbnail extends StatelessWidget {
  const _CheerThumbnail();
  @override
  Widget build(BuildContext context) => Container(width: 60, height: 60, decoration: const BoxDecoration(color: Color(0xFFFFF4E6), shape: BoxShape.circle), child: const Icon(Icons.emoji_people, color: Color(0xFFFF9800), size: 36));
}

class _BookThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _BookThumbnail({this.imageUrl});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(4), child: Container(width: 60, height: 80, color: const Color(0xFFF3F3F3), child: imageUrl != null ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book, color: kNotifBorder, size: 28)) : const Icon(Icons.book, color: kNotifBorder, size: 28)));
}

class _RewardThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _RewardThumbnail({this.imageUrl});
  @override
  Widget build(BuildContext context) => SizedBox(width: 60, height: 60, child: imageUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl!, fit: BoxFit.contain)) : const Icon(Icons.star_rounded, color: Colors.amber, size: 40));
}

class _CircleThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String type;
  final String? reminderType;
  const _CircleThumbnail({this.imageUrl, required this.type, this.reminderType});
  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.notifications;
    if (type.contains('NOTICE')) icon = Icons.campaign;
    else if (reminderType == 'READING_REMINDER') icon = Icons.menu_book;

    // 혹시 모를 폴백을 위해 한번 더 체크
    else if (type.contains('REWARD') || type.contains('BADGE')) icon = Icons.star_rounded;

    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: kNotifGreenLight, shape: BoxShape.circle, border: Border.all(color: kNotifGreen.withOpacity(0.3))),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icon, color: kNotifGreen, size: 26)))
          : Icon(icon, color: kNotifGreen, size: 26),
    );
  }
}