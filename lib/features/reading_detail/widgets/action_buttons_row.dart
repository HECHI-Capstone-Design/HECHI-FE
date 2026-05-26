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
          top: BorderSide(width: 1, color: Color(0xFFD4D4D4)),
          bottom: BorderSide(width: 1, color: Color(0xFFD4D4D4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            '북마크',
            Icons.bookmark_border,
            const Color(0xFFE8F5E9), // BookmarkItem 배경색
            const Color(0xFF4DB56C), // BookmarkItem 아이콘색
            onTap: () => _navigateToNote(detailController.bookId.value, 0),
          ),
          _buildDivider(),
          _buildActionButton(
            '하이라이트',
            Icons.push_pin_outlined,
            const Color(0xFFFFF9C4), // HighlightItem 배경색
            const Color(0xFFFBC02D), // HighlightItem 아이콘색
            onTap: () => _navigateToNote(detailController.bookId.value, 1),
          ),
          _buildDivider(),
          _buildActionButton(
            '메모',
            Icons.description_outlined,
            const Color(0xFFFFEBEE), // MemoItem 배경색
            const Color(0xFFEF5350), // MemoItem 아이콘색
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
      child: VerticalDivider(color: Color(0xFFD4D4D4), width: 15),
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
                color: Color(0xFF3F3F3F),
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