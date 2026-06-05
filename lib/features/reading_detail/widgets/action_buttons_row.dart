import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reading_detail_controller.dart';

class ActionButtonsRow extends StatelessWidget {
  const ActionButtonsRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detailController = Get.find<ReadingDetailController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(width: 1, color: AppColors.borderMedium),
          bottom: BorderSide(width: 1, color: AppColors.borderMedium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            '북마크',
            Icons.bookmark_border,
            AppColors.primarySurface, // BookmarkItem 배경색
            AppColors.primary, // BookmarkItem 아이콘색
            onTap: () => _navigateToNote(detailController.bookId.value, 0),
          ),
          _buildDivider(),
          _buildActionButton(
            '하이라이트',
            Icons.push_pin_outlined,
            AppColors.highlightBackground, // HighlightItem 배경색
            AppColors.star, // HighlightItem 아이콘색
            onTap: () => _navigateToNote(detailController.bookId.value, 1),
          ),
          _buildDivider(),
          _buildActionButton(
            '메모',
            Icons.description_outlined,
            AppColors.memoBackground, // MemoItem 배경색
            AppColors.error, // MemoItem 아이콘색
            onTap: () => _navigateToNote(detailController.bookId.value, 2),
          ),
        ],
      ),
    );
  }

  void _navigateToNote(int bookId, int tabIndex) {
    Get.toNamed(
      '/book_note',
      arguments: {
        'bookId': bookId,
        'tabIndex': tabIndex,
      },
    );
  }

  Widget _buildDivider() {
    return const SizedBox(
      height: 60,
      child: VerticalDivider(color: AppColors.borderMedium, width: 15),
    );
  }

  // PNG 이미지 대신 IconData와 배경색/아이콘색을 받도록 수정했습니다.
  Widget _buildActionButton(
      String label,
      IconData icon,
      Color bgColor,
      Color iconColor, {
        required VoidCallback onTap,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontFamily: 'Roboto',
                letterSpacing: 0.25,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24, // 버튼 크기에 맞춰 아이콘 사이즈 조정
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}