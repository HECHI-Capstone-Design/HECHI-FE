import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';
import 'package:hechi/app/routes.dart';

// UI 상단 공통 색상 상수
const Color kNotifGreen = Color(0xFF5C8C5A);
const Color kNotifGreenLight = Color(0xFFEAF3EA);
const Color kNotifBorder = Color(0xFFD4D4D4);
const Color kNotifTextDark = Color(0xFF3F3F3F);
const Color kNotifTextMid = Color(0xFF5F5F5F);
const Color kNotifTextGrey = Color(0xFF9E9E9E);

class GeneralNotificationTile extends StatelessWidget {
  final NotificationItem item;
  const GeneralNotificationTile({super.key, required this.item});

  // 🛠️ targetInfo를 안전하게 Map으로 파싱하는 헬퍼 함수 (팀원 최신 코드 유지)
  Map<String, dynamic> _getParsedInfo() {
    try {
      dynamic info = item.targetInfo;
      if (info is String && info.startsWith('{')) {
        return jsonDecode(info);
      } else if (info is Map) {
        return Map<String, dynamic>.from(info);
      }
    } catch (e) {
      debugPrint("🚨 targetInfo 파싱 에러: $e");
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

        // 2. 🚀 고도화된 라우팅 로직 (팀원의 Null Safety 적용 버전 채택)
        if (info['bookId'] != null) {
          final parsedBookId = int.tryParse(info['bookId'].toString());
          if (parsedBookId != null) {
            Get.toNamed(Routes.bookDetailPage, arguments: parsedBookId);
          }
        } else if (info['badgeCode'] != null || info['rewardId'] != null) {
          Get.toNamed(Routes.reward);
        } else if (info['reminderType'] != null) {
          Get.toNamed(Routes.bookStorage);
        } else if (info['noticeId'] != null) {
          Get.toNamed(Routes.customer);
        } else {
          debugPrint("🚨 라우팅 조건을 찾을 수 없습니다: $info");
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
            // 3. 🎨 썸네일 UI 분기 처리
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
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: kNotifTextDark, fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold, height: 1.3,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(item.timeAgo, style: const TextStyle(color: kNotifTextGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(color: kNotifTextMid, fontSize: 12, height: 1.45),
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

  // UI 모양 분기 함수
  Widget _buildThumbnail(Map<String, dynamic> info) {
    final String? resolvedUrl = item.imageUrl?.isNotEmpty == true
        ? item.imageUrl
        : (info['thumbnailUrl'] ?? info['image_url'] ?? info['imageUrl'] ?? info['profileUrl'] ?? info['actorProfileUrl'] ?? info['userImageUrl'])?.toString();

    // 🚀 [수정됨] 텍스트에 의존하는 겉핥기식 플래그(hasBookText) 완전 제거. 오직 '데이터'만 검증.
    final bool isSlump = item.type == 'READING_SLUMP' || info['reminderType'] == 'READING_SLUMP';
    final bool isReward = info['rewardId'] != null || item.type == 'REWARD' || item.type.contains('BADGE');
    final bool hasBookId = info['bookId'] != null;

    // 🥇 1순위 : 슬럼프 알림 (type 데이터 기반)
    if (isSlump) {
      return const _CheerThumbnail();
    }

    // 🥈 2순위 : 리워드 / 뱃지 (type, rewardId 데이터 기반)
    if (isReward) {
      return _RewardThumbnail(imageUrl: resolvedUrl);
    }

    // 🥉 3순위 : 특정 도서 알림 (반드시 bookId 데이터가 존재해야만 책 표지 렌더링)
    if (hasBookId) {
      return _BookThumbnail(imageUrl: resolvedUrl);
    }

    // 4순위 : 일반 공지 및 기타 리마인더 (펼쳐진 책 아이콘 처리를 위해 reminderType 전달)
    return _CircleThumbnail(
      imageUrl: resolvedUrl,
      type: item.type,
      reminderType: info['reminderType']?.toString(), // 🚀 깔끔하게 텍스트 하나만 전달
    );
  }
}

// 🙌 독서 슬럼프 극복 응원 위젯
class _CheerThumbnail extends StatelessWidget {
  const _CheerThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(color: Color(0xFFFFF4E6), shape: BoxShape.circle),
      child: const Icon(Icons.emoji_people, color: Color(0xFFFF9800), size: 36),
    );
  }
}

// 📚 책 표지 썸네일 (60x80 비율 유지)
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

// 🌟 리워드 썸네일
class _RewardThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _RewardThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60, height: 60,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl!, fit: BoxFit.contain))
          : const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
    );
  }
}

// 🟢 동그라미 아이콘 위젯 (종 모양 -> 펼쳐진 책 모양 완벽 분기)
class _CircleThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String type;
  final String? reminderType;

  const _CircleThumbnail({super.key, this.imageUrl, required this.type, this.reminderType});

  @override
  Widget build(BuildContext context) {
    IconData icon;

    // 🚀 완벽한 데이터 기반 분기
    if (type.contains('BADGE')) {
      icon = Icons.military_tech;
    } else if (type.contains('NOTICE')) {
      icon = Icons.campaign;
    } else if (reminderType == 'READING_REMINDER') {
      // ✅ targetInfo 안의 reminderType이 READING_REMINDER일 경우 펼쳐진 책
      icon = Icons.menu_book;
    } else {
      // 그 외 일반 알림은 기본 종 모양
      icon = Icons.notifications;
    }

    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: kNotifGreenLight,
        shape: BoxShape.circle,
        border: Border.all(color: kNotifGreen.withOpacity(0.3), width: 1),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(icon, color: kNotifGreen, size: 26),
        ),
      )
          : Icon(icon, color: kNotifGreen, size: 26),
    );
  }
}