import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/badge_model.dart';

class BadgeItemWidget extends StatelessWidget {
  final BadgeModel badge;

  const BadgeItemWidget({Key? key, required this.badge}) : super(key: key);

  // 💡 각 배지의 'code'를 기반으로 15개 리워드 모두 고유한 아이콘을 리턴합니다.
  IconData _getBadgeIcon(String code) {
    switch (code) {
      // 1. 독서 관련 배지 (책/성장/도서관)
      case 'beginner_5':
        return Icons.menu_book_rounded;       // 책을 펼친 모양 (독서 시작)
      case 'pro_10':
        return Icons.auto_stories_rounded;   // 책을 여러 권 넘기는 모양 (프로)
      case 'master_20':
        return Icons.psychology_rounded;     // 지식과 마스터의 느낌 (뇌/지혜)
      case 'library_50':
        return Icons.account_balance_rounded; // 웅장한 도서관/신전 모양 (걸어다니는 도서관)

      // 2. 별점 관련 배지 (별/장인)
      case 'fairy_10':
        return Icons.auto_awesome_rounded;   // 반짝이는 요정 가루 느낌
      case 'craft_30':
        return Icons.star_half_rounded;      // 별점을 섬세하게 깎는 장인 느낌
      case 'restaurant_100':
        return Icons.star_rounded;           // 가장 꽉 찬 황금빛 별 (별점 맛집)

      // 3. 리뷰 관련 배지 (펜/깃털/작가)
      case 'poem_5':
        return Icons.history_edu_rounded;    // 깃털 펜으로 시를 쓰는 느낌
      case 'short_15':
        return Icons.edit_note_rounded;      // 노트를 작성하는 느낌 (단편)
      case 'author_30':
        return Icons.workspace_premium_rounded; // 등단 작가의 명예로운 메달/트로피

      // 4. 장르 관련 배지 (하트/나침반/취향)
      case 'lover_10':
        return Icons.favorite_rounded;       // 한 우물만 파는 장르 러버 (하트)
      case 'omnireader_10genres':
        return Icons.explore_rounded;        // 온갖 장르를 탐험하는 잡독러 (나침반)

      // 5. 위시리스트 배지 (소망/바구니)
      case 'desire_30':
        return Icons.shopping_bag_rounded;   // 독서 욕망을 담는 위시 바구니

      // 6. 북마크 배지 (수집/활자)
      case 'collector_10':
        return Icons.bookmark_rounded;       // 문장 수집가 (북마크 리본)
      case 'lover_50':
        return Icons.collections_bookmark_rounded; // 북마크가 겹겹이 쌓인 활자 애호가

      default:
        return Icons.emoji_events_rounded;   // 기본Fallback 트로피
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEarned = badge.isEarned;

    return GestureDetector(
      onTap: () => _showBadgeDetailDialog(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: isEarned ? const Color(0xFFF6FBF7) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isEarned ? const Color(0xFFE2F3E7) : const Color(0xFFEAEAEA),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: isEarned
                  ? Center(
                      child: Icon(
                        _getBadgeIcon(badge.code), // 💡 고유 아이콘 함수 호출
                        color: const Color(0xFF5CBA74),
                        size: 36,
                      ),
                    )
                  : const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD2D2D2),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          isEarned
              ? Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A2A2A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                  child: Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9E9E9E),
                    ),
                    maxLines: 2,
                  ),
                ),
        ],
      ),
    );
  }

  void _showBadgeDetailDialog(BuildContext context) {
    final widgetIcon = Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(16),
      child: badge.isEarned
          ? Center(
              child: Icon(
                _getBadgeIcon(badge.code), // 💡 팝업 상세창에도 동일한 고유 아이콘 적용
                color: const Color(0xFF66BB6A),
                size: 54,
              ),
            )
          : const Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ),
    );

    final widgetTitle = Text(
      badge.title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: -0.5,
      ),
    );

    final widgetConditionBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        badge.description,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575),
        ),
      ),
    );

    final widgetStatusText = Text(
      badge.isEarned ? '달성 완료!' : '획득하지 못한 리워드',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: badge.isEarned ? const Color(0xFF66BB6A) : const Color(0xFFB0B0B0),
      ),
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.only(top: 36, left: 24, right: 24, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widgetIcon,
              const SizedBox(height: 24),
              widgetTitle,
              const SizedBox(height: 12),
              widgetConditionBox,
              const SizedBox(height: 16),
              widgetStatusText,
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}