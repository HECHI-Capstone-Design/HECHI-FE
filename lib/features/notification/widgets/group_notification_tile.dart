import 'package:hechi/app/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';
import 'package:hechi/app/routes.dart'; // ✅ 라우트 임포트 유지

// UI 상단 공통 색상 상수
final Color kNotifGreen = AppColors.primaryLight;
final Color kNotifGreenLight = AppColors.primarySurface;
final Color kNotifBorder = AppColors.borderMedium;
final Color kNotifTextDark = AppColors.textDark;
final Color kNotifTextMid = AppColors.textDark;
final Color kNotifTextGrey = AppColors.textHint;

class GroupNotificationTile extends StatelessWidget {
  final NotificationItem item;

  const GroupNotificationTile({Key? key, required this.item}) : super(key: key);

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
        debugPrint("📢 [그룹 알림 터치!] type: ${item.type}, targetInfo: $info");

        // 2. 🚀 팀장님의 최신 라우팅 로직 적용 (String 하나만 깔끔하게 넘김)
        if (info.containsKey('groupId')) {
          final String groupId = info['groupId'].toString();
          final String? postId = info['postId']?.toString();
          final String? commentId = info['commentId']?.toString();

          // 좋아요·댓글 알림은 postId가 있으면 해당 게시글로 바로 이동
          if ((item.type.contains('LIKE') || item.type.contains('COMMENT')) && postId != null) {
            Get.toNamed(Routes.groupMain, arguments: {
              'groupId': groupId,
              'postId': postId,
              'commentId': commentId, // 댓글 알림일 때만 non-null
            });
          } else {
            Get.toNamed(Routes.groupMain, arguments: groupId);
          }
        } else {
          debugPrint("🚨 그룹 ID를 찾을 수 없습니다. info: $info");
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
            // 3. 🎨 썸네일 UI 분기 처리 (가입/탈퇴/삭제/미션 모두 반영)
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
                            color: kNotifGreen, fontSize: 13,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(item.timeAgo, style: TextStyle(color: kNotifTextGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '· ${item.description}',
                    style: TextStyle(color: kNotifTextMid, fontSize: 13, height: 1.4),
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

  // 🖼️ 썸네일 분기 함수
  Widget _buildThumbnail(Map<String, dynamic> info) {
    final String? groupImageUrl = item.imageUrl?.isNotEmpty == true
        ? item.imageUrl
        : (info['thumbnailUrl'] ?? info['image_url'] ?? info['imageUrl'])?.toString();

    bool isMission = item.type.contains('MISSION');

    // 🚀 확실한 가입/탈퇴 방어 로직 (텍스트 검사까지 포함하여 완벽하게 캐치)
    bool isJoinOrLeave = item.type.contains('JOIN') ||
        item.type.contains('LEAVE') ||
        item.type.contains('EXIT') ||
        (info['eventKind']?.toString().contains('JOIN') ?? false) ||
        (info['eventKind']?.toString().contains('LEAVE') ?? false) ||
        item.description.endsWith('가입했어요.') ||
        item.description.endsWith('탈퇴했어요.');

    // 🚨 그룹 삭제 로직 추가
    bool isDelete = item.type.contains('DELETE') ||
        item.description.endsWith('삭제되었어요.');

    // 좋아요·댓글·반응 등 사용자 행위 알림은 발신자 프로필 표시
    bool isSocialInteraction = item.type.contains('LIKE') ||
        item.type.contains('COMMENT') ||
        item.type.contains('REACTION');

    if (isMission) {
      return _BookThumbnail(imageUrl: groupImageUrl);
    } else if (isJoinOrLeave || isSocialInteraction) {
      final String? userProfileUrl = item.senderProfileImageUrl?.isNotEmpty == true
          ? item.senderProfileImageUrl
          : (info['actorProfileUrl'] ?? info['profileUrl'] ?? info['userImageUrl'])?.toString();
      return _ProfileThumbnail(imageUrl: userProfileUrl);
    } else if (isDelete) {
      // 삭제된 그룹은 회색 그룹 오프 아이콘 띄우기
      return Container(
        width: 60, height: 60,
        decoration: const BoxDecoration(color: AppColors.backgroundGrey, shape: BoxShape.circle),
        child: const Icon(Icons.group_off, color: AppColors.textHint, size: 28),
      );
    } else {
      return _GroupAvatar(imageUrl: groupImageUrl, type: item.type);
    }
  }
}

// 📚 책 표지 썸네일 (60x80 일괄 적용)
class _BookThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _BookThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 60, height: 80, color: AppColors.divider,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.book, color: kNotifBorder, size: 28))
            : Icon(Icons.book, color: kNotifBorder, size: 28),
      ),
    );
  }
}

// 👤 그룹 가입/탈퇴 (인스타 팔로우 스타일) 게스트 프로필 썸네일
class _ProfileThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _ProfileThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(
        color: AppColors.border,
        shape: BoxShape.circle,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
        child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40)),
      )
          : const Icon(Icons.person, color: Colors.white, size: 40),
    );
  }
}

// 🟢 그룹 기본 동그라미 아이콘 위젯 (공지사항 등)
class _GroupAvatar extends StatelessWidget {
  final String? imageUrl;
  final String type;
  const _GroupAvatar({this.imageUrl, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData defaultIcon = Icons.group;

    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: kNotifGreenLight, shape: BoxShape.circle, border: Border.all(color: kNotifGreen.withOpacity(0.3), width: 1)),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(defaultIcon, color: kNotifGreen, size: 30)))
          : Icon(defaultIcon, color: kNotifGreen, size: 30),
    );
  }
}