import 'package:hechi/app/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';
import 'package:hechi/app/routes.dart';


final Color kNotifGreen = AppColors.primaryLight;
final Color kNotifGreenLight = AppColors.primarySurface;
final Color kNotifBorder = AppColors.borderMedium;
final Color kNotifTextDark = AppColors.textDark;
final Color kNotifTextMid = AppColors.textDark;
final Color kNotifTextGrey = AppColors.textHint;

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

        Get.find<NotificationController>().markAsRead(item.notificationId);


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
          border: Border(bottom: BorderSide(width: 0.5, color: kNotifBorder)),
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
                      Text(item.timeAgo, style: TextStyle(color: kNotifTextGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.description, style: TextStyle(color: kNotifTextMid, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildThumbnail(Map<String, dynamic> info) {
    final String? resolvedUrl = item.imageUrl?.isNotEmpty == true ? item.imageUrl : (info['thumbnailUrl'] ?? info['imageUrl'])?.toString();
    final String? reminderType = info['reminderType']?.toString();

    if (item.type.contains('SLUMP') || (reminderType?.contains('SLUMP') ?? false)) return const _CheerThumbnail();


    if (info['rewardId'] != null || info['badgeCode'] != null || item.type.contains('REWARD') || item.type.contains('BADGE')) return _RewardThumbnail(imageUrl: resolvedUrl);

    if (info['bookId'] != null) return _BookThumbnail(imageUrl: resolvedUrl);


    final senderImage = item.senderProfileImageUrl?.isNotEmpty == true
        ? item.senderProfileImageUrl
        : null;

    return _CircleThumbnail(
      imageUrl: senderImage ?? resolvedUrl,
      type: item.type,
      reminderType: reminderType,
    );
  }
}


class _CheerThumbnail extends StatelessWidget {
  const _CheerThumbnail();
  @override
  Widget build(BuildContext context) => Container(width: 60, height: 60, decoration: const BoxDecoration(color: Color(0xFFFFF4E6), shape: BoxShape.circle), child: const Icon(Icons.emoji_people, color: Color(0xFFFF9800), size: 36));
}

class _BookThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _BookThumbnail({this.imageUrl});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(4), child: Container(width: 60, height: 80, color: AppColors.divider, child: imageUrl != null ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.book, color: kNotifBorder, size: 28)) : Icon(Icons.book, color: kNotifBorder, size: 28)));
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
    // 시스템 알림 타입은 전용 아이콘 사용
    if (type.contains('NOTICE')) {
      return Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: kNotifGreenLight, shape: BoxShape.circle, border: Border.all(color: kNotifGreen.withOpacity(0.3))),
        child: const Icon(Icons.campaign, color: AppColors.primary, size: 26),
      );
    }
    if (reminderType == 'READING_REMINDER') {
      return Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: kNotifGreenLight, shape: BoxShape.circle, border: Border.all(color: kNotifGreen.withOpacity(0.3))),
        child: const Icon(Icons.menu_book, color: AppColors.primary, size: 26),
      );
    }

    // 사용자 프로필 이미지 있으면 표시, 없으면 회색 게스트 아이콘
    return Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 30)))
          : const Icon(Icons.person, color: Colors.white, size: 30),
    );
  }
}
