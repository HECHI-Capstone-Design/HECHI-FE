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

        if (item.type.contains('SLUMP')) {
          // 일반 독서 격려 알림 → 항상 보관함 (bookId 유무 무관)
          Get.toNamed(Routes.bookStorage);
        } else if (reminderType == 'READING_REMINDER') {
          // 특정 책 언급 리마인더 → bookId 있으면 해당 책 상세, 없으면 보관함
          final bookId = info['bookId'];
          if (bookId != null) {
            Get.toNamed(Routes.bookDetailPage, arguments: int.tryParse(bookId.toString()));
          } else {
            Get.toNamed(Routes.bookStorage);
          }
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

    // AI 독서 요약: bookId 체크보다 먼저 — AI 요약 알림에도 bookId가 포함되어 있어서 순서가 중요
    if (item.type.contains('AI') || item.type.contains('SUMMARY')) {
      return _AiSummaryThumbnail(imageUrl: resolvedUrl ?? info['bookCoverUrl']?.toString());
    }

    if (info['bookId'] != null) return _BookThumbnail(imageUrl: resolvedUrl);

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

/// AI 독서 요약 전용 썸네일: 책 표지 있으면 표지, 없으면 귀여운 독서 캐릭터.
class _AiSummaryThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _AiSummaryThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // 고정 60x80 박스 안에서 클립. (OverflowBox는 높이 무한 제약을 받는
    // ListView 아이템 안에서 레이아웃 예외를 일으키므로 사용하지 않음)
    return SizedBox(
      width: 60,
      height: 80,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        // 캐릭터 이미지를 우선 사용. 파일이 없으면 직접 그린 캐릭터로 대체.
        child: Image.asset(
          'assets/icons/ai_summary_character.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const _AiSummaryCharacter(),
        ),
      ),
    );
  }
}

/// AI 로봇 독서 캐릭터 — 둥근 헬멧 로봇이 파란 책을 들고 읽는 모습
class _AiSummaryCharacter extends StatelessWidget {
  const _AiSummaryCharacter();

  @override
  Widget build(BuildContext context) {
    const bodyLight = Color(0xFFF2F6FC);
    const bodyMid = Color(0xFFDDE6F2);
    const bodyShade = Color(0xFFC4D2E4);

    return Container(
      width: 60,
      height: 80,
      color: const Color(0xFFFAFCFF),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 다리
          Positioned(
            bottom: 0,
            left: 22,
            child: _softBlob(7, 16, bodyLight, bodyShade, radius: 4),
          ),
          Positioned(
            bottom: 0,
            right: 22,
            child: _softBlob(7, 16, bodyLight, bodyShade, radius: 4),
          ),
          // 몸통
          Positioned(
            bottom: 10,
            left: 18,
            right: 18,
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bodyLight, bodyMid, bodyShade],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0, 2)),
                ],
              ),
            ),
          ),
          // 오른팔 (뒤쪽 — 책 너머로 살짝)
          Positioned(
            bottom: 20,
            right: 8,
            child: _softBlob(11, 11, bodyLight, bodyShade, radius: 6),
          ),
          // 머리 (둥근 사각형 + 구체 음영)
          Positioned(
            top: 2,
            left: 9,
            child: Container(
              width: 42,
              height: 40,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(-0.4, -0.5),
                  radius: 1.0,
                  colors: [Color(0xFFFFFFFF), Color(0xFFE6EDF6), Color(0xFFC9D7E8)],
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
                ],
              ),
            ),
          ),
          // 얼굴 면 (살짝 파란 둥근 사각형, 안쪽 음영)
          Positioned(
            top: 9,
            left: 15,
            child: Container(
              width: 30,
              height: 27,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.95,
                  colors: [Color(0xFFF2F8FF), Color(0xFFDDEAF8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF9DB4CE).withOpacity(0.3), blurRadius: 2, offset: const Offset(0, 1)),
                ],
              ),
            ),
          ),
          // 왼쪽 눈
          Positioned(top: 17, left: 22, child: _eye()),
          // 오른쪽 눈
          Positioned(top: 17, right: 22, child: _eye()),
          // 왼쪽 볼
          Positioned(top: 24, left: 16, child: _cheek()),
          // 오른쪽 볼
          Positioned(top: 24, right: 16, child: _cheek()),
          // 미소
          Positioned(
            top: 24,
            left: 24,
            child: CustomPaint(size: const Size(12, 6), painter: _SmilePainter()),
          ),
          // 머리 상단 광택
          Positioned(
            top: 8,
            left: 18,
            child: Container(
              width: 8,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // 파란 책 (비스듬히 펼친 입체 형태)
          Positioned(
            bottom: 14,
            left: 2,
            child: Transform.rotate(
              angle: -0.12,
              child: SizedBox(
                width: 42,
                height: 30,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽 표지 (앞면 — 가장 밝은 파랑)
                    Container(
                      width: 19,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4C82F7), Color(0xFF2E63E0)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF1E4AB8).withOpacity(0.4), blurRadius: 5, offset: const Offset(0, 3)),
                        ],
                      ),
                    ),
                    // 척추 접힘 (어두운 안쪽)
                    Container(width: 3, height: 28, color: const Color(0xFF1E3F94)),
                    // 오른쪽 면 (원근으로 좁아지는 어두운 파랑)
                    Container(
                      width: 15,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF2A5AD4), Color(0xFF3D6FE8)],
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 왼손 (책을 잡은 앞쪽 손)
          Positioned(
            bottom: 12,
            left: 0,
            child: _softBlob(11, 11, bodyLight, bodyShade, radius: 6),
          ),
        ],
      ),
    );
  }

  static Widget _softBlob(double w, double h, Color light, Color shade, {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, shade],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  static Widget _eye() => Container(
        width: 5,
        height: 7,
        decoration: const BoxDecoration(color: Color(0xFF3A4A5E), shape: BoxShape.circle),
      );

  static Widget _cheek() => Container(
        width: 7,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFFF9CA3).withOpacity(0.7),
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A4A5E)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SmilePainter oldDelegate) => false;
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
