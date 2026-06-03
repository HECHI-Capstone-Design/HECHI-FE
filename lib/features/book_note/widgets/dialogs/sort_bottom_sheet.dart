import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/book_note_controller.dart';

class SortBottomSheet extends StatelessWidget {
  final String type; // bookmark | highlight

  const SortBottomSheet({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookNoteController>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15,),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 0.5,
                    color: Color(0xFFD4D4D4),
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '정렬',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: InkWell(
                      onTap: () => Get.back(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF4DB56C),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildContent(controller),
            const SizedBox(height: 30,),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 분기: Bookmark / Highlight / Memo
  // =====================================================
  Widget _buildContent(BookNoteController controller) {
    switch (type) {
      case "bookmark":
        return _bookmarkOptions(controller);
      case "highlight":
        return _highlightOptions(controller);
      case "memo":
        return _memoOptions(controller);
      default:
        return const SizedBox.shrink();
    }
  }

  // =====================================================
  // BOOKMARK 정렬 옵션
  // 날짜 순 / 페이지 순
  // =====================================================
  Widget _bookmarkOptions(BookNoteController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOption(
          label: "최신 순",
          isSelected: controller.sortTypeBookmark.value == "date",
          onTap: () {
            controller.sortTypeBookmark.value = "date";
            controller.sortTextBookmark.value = "최신 순";
            controller.sortBookmarks();
            Get.back();
          },
        ),
        _buildOption(
          label: "페이지 순",
          isSelected: controller.sortTypeBookmark.value == "page",
          onTap: () {
            controller.sortTypeBookmark.value = "page";
            controller.sortTextBookmark.value = "페이지 순";
            controller.sortBookmarks();
            Get.back();
          },
        ),
      ],
    );
  }

  // =====================================================
  // HIGHLIGHT 정렬 옵션
  // 날짜 순 / 페이지 순
  // =====================================================
  Widget _highlightOptions(BookNoteController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOption(
          label: "최신 순",
          isSelected: controller.sortTypeHighlight.value == "date",
          onTap: () {
            controller.sortTypeHighlight.value = "date";
            controller.sortTextHighlight.value = "최신 순";
            controller.sortHighlights();
            Get.back();
          },
        ),
        _buildOption(
          label: "페이지 순",
          isSelected: controller.sortTypeHighlight.value == "page",
          onTap: () {
            controller.sortTypeHighlight.value = "page";
            controller.sortTextHighlight.value = "페이지 순";
            controller.sortHighlights();
            Get.back();
          },
        ),
      ],
    );
  }

  // =====================================================
  // MEMO 정렬 옵션
  // 최신 순 / 오래된 순
  // =====================================================
  Widget _memoOptions(BookNoteController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOption(
          label: "최신 순",
          isSelected: controller.sortTypeMemo.value == "date",
          onTap: () {
            controller.sortTypeMemo.value = "date";
            controller.sortTextMemo.value = "최신 순";
            controller.sortMemos();
            Get.back();
          },
        ),
        _buildOption(
          label: "오래된 순",
          isSelected: controller.sortTypeMemo.value == "oldest",
          onTap: () {
            controller.sortTypeMemo.value = "oldest";
            controller.sortTextMemo.value = "오래된 순";
            controller.sortMemos();
            Get.back();
          },
        ),
      ],
    );
  }

  // =====================================================
  // 공통 UI
  // =====================================================
  Widget _buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0.5,
              color: Color(0xFFD4D4D4),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 22,
                color: Color(0xFF4DB56C),
              ),
          ],
        ),
      ),
    );
  }
}
