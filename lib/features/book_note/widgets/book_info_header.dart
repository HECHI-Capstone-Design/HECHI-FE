import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_note_controller.dart';
import '../controllers/ai_summary_controller.dart';
import '../pages/ai_summary_page.dart';

class BookInfoHeader extends GetView<BookNoteController> {
  const BookInfoHeader({super.key});

  String _formatAuthor(dynamic authorsData) {
    if (authorsData == null) return "";

    if (authorsData is List) {
      if (authorsData.isEmpty) return "";

      final firstAuthor = authorsData[0].toString();

      if (authorsData.length == 1) {
        return firstAuthor;
      } else {
        return "$firstAuthor 외 ${authorsData.length - 1}명";
      }
    }
    return authorsData.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final book = controller.bookInfo;
        final authorText = _formatAuthor(book['authors']);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      final hasContent = controller.hasAiSummaryContent();
                      if (hasContent) {
                        Get.to(
                          () => const AiSummaryPage(),
                          binding: BindingsBuilder(() {
                            Get.lazyPut(() => AiSummaryController());
                          }),
                        );
                      } else {
                        _showNoContentDialog();
                      }
                    },
                    child: Obx(() {
                      final active = controller.hasSummary.value;
                      return Container(
                        width: 70,
                        height: 23,
                        decoration: ShapeDecoration(
                          color: active ? const Color(0xFFD1EDD9) : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: active ? const Color(0xFF4DB56C) : const Color(0xFFABABAB),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'AI 요약',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? const Color(0xFF4DB56C) : const Color(0xFFABABAB),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.25,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // 책 제목
                  Text(
                    book['title'] ?? "",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 저자
                  Text(
                    authorText,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // 책 표지
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
                image: book['thumbnail'] != null
                    ? DecorationImage(image: NetworkImage(book['thumbnail']), fit: BoxFit.cover)
                    : null,
              ),
            ),
          ],
        );
      }),
    );
  }
}

void _showNoContentDialog() {
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 200,
        height: 107,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text(
                  'AI 요약이 불가합니다.\n독서기록을 남겨주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3F3F3F),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.75,
                  ),
                ),
              ),
            ),
            Container(height: 1, color: const Color(0xFFF3F3F3)),
            SizedBox(
              height: 36,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  onTap: () => Get.back(),
                  child: const Center(
                    child: Text(
                      '닫기',
                      style: TextStyle(
                        color: Color(0xFF4DB56C),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}