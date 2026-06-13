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

        // SLUMP/READING_REMINDER는 bookId보다 먼저 처리: 책 정보가 targetInfo에 있어도 보관함으로 이동
        if (item.type.contains('SLUMP') || reminderType == 'READING_REMINDER') {
          Get.toNamed(Routes.bookStorage);
        } else if (info['groupId'] != null) {
          Get.toNamed(Routes.groupMain, arguments: info['groupId'].toString());
        } else if (info['bookId'] != null) {
          Get.toNamed(Routes.bookDetailPage, arguments: int.tryParse(info['bookId'].toString()));
        } else if (info['badgeCode'] != null || info['rewardId'] != null || item.type.contains('REWARD') || item.type.contains('BADGE')) {
          Get.toNamed(Routes.reward);
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
                        child: Text(_resolvedTitle(), style: TextStyle(color: kNotifTextDark, fontSize: 14, fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold)),
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


  // senderName이 있고 컬렉션 좋아요 타입이면 SNS 스타일 제목으로 표시
  String _resolvedTitle() {
    final name = item.senderName;
    if (name != null && name.isNotEmpty && item.type.contains('COLLECTION') && item.type.contains('LIKE')) {
      return '$name님이 좋아요를 눌렀어요';
    }
    return item.title;
  }

  Widget _buildThumbnail(Map<String, dynamic> info) {
    final String? resolvedUrl = item.imageUrl?.isNotEmpty == true ? item.imageUrl : (info['thumbnailUrl'] ?? info['imageUrl'])?.toString();
    final String? reminderType = info['reminderType']?.toString();

    if (item.type.contains('SLUMP') || (reminderType?.contains('SLUMP') ?? false)) return const _CheerThumbnail();


    if (info['rewardId'] != null || info['badgeCode'] != null || item.type.contains('REWARD') || item.type.contains('BADGE')) return _RewardThumbnail(imageUrl: resolvedUrl);

    if (info['bookId'] != null) return _BookThumbnail(imageUrl: resolvedUrl);

    // AI 독서 요약 → 책 표지 + AI 배지 오버레이
    if (item.type.contains('AI') || item.type.contains('SUMMARY')) {
      return _AiSummaryThumbnail(imageUrl: resolvedUrl ?? info['bookCoverUrl']?.toString());
    }

    // READING_REMINDER: 독서 중인 책 커버 스택 (백엔드가 bookCovers 배열 제공 시 스택, 미제공 시 회색 아이콘)
    if (reminderType == 'READING_REMINDER') {
      final dynamic coversRaw = info['bookCovers'];
      final List<String> covers = coversRaw is List
          ? coversRaw.whereType<String>().where((s) => s.isNotEmpty).toList()
          : [];
      return _ReadingReminderThumbnail(bookCovers: covers);
    }

    final senderImage = item.senderProfileImageUrl?.isNotEmpty == true
        ? item.senderProfileImageUrl
        : null;

    return _CircleThumbnail(
      imageUrl: senderImage ?? resolvedUrl,
      type: item.type,
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
  const _CircleThumbnail({this.imageUrl, required this.type});
  @override
  Widget build(BuildContext context) {
    // 시스템 공지 알림은 전용 아이콘 사용
    if (type.contains('NOTICE')) {
      return Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: kNotifGreenLight, shape: BoxShape.circle, border: Border.all(color: kNotifGreen.withOpacity(0.3))),
        child: const Icon(Icons.campaign, color: AppColors.primary, size: 26),
      );
    }

    // 사용자 프로필 이미지 있으면 표시, 없으면 회색 게스트 아이콘
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.person, color: Colors.grey.shade500, size: 30)))
          : Icon(Icons.person, color: Colors.grey.shade500, size: 30),
    );
  }
}

/// AI 독서 요약 전용 썸네일: 책 표지 위에 작은 AI 배지 오버레이.
/// 책 표지 URL은 백엔드 targetInfo.bookCoverUrl 또는 thumbnailUrl로 제공받아야 함.
class _AiSummaryThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _AiSummaryThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 80,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 60,
              height: 80,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.divider, child: Icon(Icons.book, color: kNotifBorder, size: 28)))
                  : Container(color: AppColors.divider, child: Icon(Icons.book, color: kNotifBorder, size: 28)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: Color(0xFF4DB56C), shape: BoxShape.circle),
              child: const Center(child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
    );
  }
}

/// READING_REMINDER 전용 썸네일:
/// 백엔드가 targetInfo.bookCovers 배열을 제공하면 실제 책 커버를 팬 형태로 스택 렌더링.
/// 미제공(빈 배열)이면 회색 아이콘으로 graceful fallback.
///
/// 백엔드 요구사항:
///   READING_REMINDER 알림의 targetInfo에 아래 필드 추가 필요:
///   "bookCovers": ["https://cover1.jpg", "https://cover2.jpg", "https://cover3.jpg"]
///   (현재 독서 중인 책 커버 URL 목록, 최대 3개)
class _ReadingReminderThumbnail extends StatelessWidget {
  final List<String> bookCovers;
  const _ReadingReminderThumbnail({required this.bookCovers});

  @override
  Widget build(BuildContext context) {
    if (bookCovers.isEmpty) {
      // 백엔드 bookCovers 미제공 시 회색 아이콘 fallback (초록 절대 사용 안 함)
      return Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
        child: Icon(Icons.menu_book, color: Colors.grey.shade500, size: 26),
      );
    }

    final covers = bookCovers.take(3).toList();
    final int count = covers.length;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(count, (i) {
          // 여러 권일수록 팬 형태로 배치 (좌→우, 약간 회전)
          final double angle = count > 1 ? (i - (count - 1) / 2.0) * 0.18 : 0.0;
          final double xOffset = count > 1 ? (i - (count - 1) / 2.0) * 9.0 : 0.0;
          return Transform.translate(
            offset: Offset(xOffset, 0),
            child: Transform.rotate(
              angle: angle,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(
                  covers[i],
                  width: 34,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 34,
                    height: 48,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.book, color: Colors.grey.shade500, size: 16),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
