import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';
import 'package:hechi/app/routes.dart'; // ✅ 라우트 임포트 추가

// UI 상단 공통 색상 상수 (General과 통일)
const Color kNotifGreen = Color(0xFF5C8C5A);
const Color kNotifGreenLight = Color(0xFFEAF3EA);
const Color kNotifBorder = Color(0xFFD4D4D4);
const Color kNotifTextDark = Color(0xFF3F3F3F);
const Color kNotifTextMid = Color(0xFF5F5F5F);
const Color kNotifTextGrey = Color(0xFF9E9E9E);

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
        // 1. 기존 기능: 알림 읽음 처리
        Get.find<NotificationController>().markAsRead(item.notificationId);
<<<<<<< Updated upstream
        print("📢 [그룹 알림 터치!] type: ${item.type}, targetInfo: $info");

        if (info.containsKey('groupId')) {
          // ✅ GroupController는 무조건 'String' 타입의 ID 하나만 받습니다!
          final String finalGroupIdStr = info['groupId'].toString();
          Get.toNamed(Routes.groupMain, arguments: finalGroupIdStr);
        } else {
          print("🚨 그룹 ID를 찾을 수 없습니다. info: $info");
=======

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
>>>>>>> Stashed changes
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
          crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
          children: [
            // 🎨 썸네일 UI 분기 처리
            _buildThumbnail(info),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded( // 텍스트 오버플로우 방지
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

  // 🖼️ 썸네일 분기 함수
  Widget _buildThumbnail(Map<String, dynamic> info) {
    // 1. 그룹 기본 이미지 (미션이나 일반 공지용)
    final String? groupImageUrl = item.imageUrl?.isNotEmpty == true
        ? item.imageUrl
        : (info['thumbnailUrl'] ?? info['image_url'] ?? info['imageUrl'])?.toString();

    bool isMission = item.type.contains('MISSION');
    bool isJoinOrLeave = item.type.contains('JOIN') || item.type.contains('LEAVE') || (info['eventKind']?.toString().contains('JOIN') ?? false);

    // ✅ 미션(책)은 네모 썸네일
    if (isMission) {
      return _BookThumbnail(imageUrl: groupImageUrl);
    }
    // 🚀 [수정됨] 가입/탈퇴는 '그룹 이미지'를 무시하고 '가입한 유저'의 프사만 찾습니다!
    else if (isJoinOrLeave) {
      // 백엔드가 targetInfo에 유저 프사를 주면 그걸 쓰고, 없으면 무조건 게스트 아이콘 띄움
      final String? userProfileUrl = (info['profileUrl'] ?? info['actorProfileUrl'] ?? info['userImageUrl'])?.toString();
      return _ProfileThumbnail(imageUrl: userProfileUrl);
    }
    // ✅ 나머지 일반 그룹 공지는 동그라미 기본
    else {
      return _GroupAvatar(imageUrl: groupImageUrl, type: item.type);
    }
  }
}

// 📚 책 표지 썸네일 (60x60 일괄 적용)
class _BookThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _BookThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 60, height: 60, color: const Color(0xFFF3F3F3),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book, color: kNotifBorder, size: 28))
            : const Icon(Icons.book, color: kNotifBorder, size: 28),
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
        color: Color(0xFFE0E0E0), // 게스트 기본 배경색 (연회색)
        shape: BoxShape.circle,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
        child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40)),
      )
          : const Icon(Icons.person, color: Colors.white, size: 40), // 꽉 차는 게스트 아이콘
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