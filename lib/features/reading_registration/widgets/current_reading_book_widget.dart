// D:\HECHI\lib\features\reading_registration\widgets\current_reading_book_widget.dart 전면 교체

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/reading_library_model.dart';
import '../controllers/reading_registration_controller.dart';

class CurrentReadingBookWidget extends StatelessWidget {
  // 🎯 [완치 핵심 1]: 외부에서 주입받아 0초로 강제 오염시키던 불필요한 'final item' 인자를 전면 삭제합니다!
  const CurrentReadingBookWidget({Key? key}) : super(key: key);

  static const Color mainColor = Color(0xFF4DB56C);

  String _formatTime(int seconds) {
    if (seconds <= 0) return "00:00";
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    if (seconds >= 3600) return "$h:$m:$s";
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReadingRegistrationController>();

    return Obx(() {
      // 🎯 [완치 핵심 2]: 이제 오직 컨트롤러가 지켜낸 완벽한 실시간 가드 데이터 스트림만 화면에 뿜어냅니다.
      final activeItem = controller.currentActiveBook.value;

      if (activeItem == null) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded, size: 40, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  "아래 목록에서 책을 선택하여\n독서를 시작하세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

      final book = activeItem.book;
      final int totalPages = book.totalPages > 0 ? book.totalPages : 1;
      final double realProgressValue = (activeItem.currentPage / totalPages).clamp(0.0, 1.0);
      final int displayPercent = (realProgressValue * 100).toInt();

      bool isReadingNow = controller.currentSession.value?.bookId == book.id;

      int currentSessionSeconds = 0;
      int totalAccumulatedSeconds = activeItem.totalSessionSeconds;

      if (isReadingNow) {
        currentSessionSeconds = controller.elapsedSeconds.value;
        totalAccumulatedSeconds += currentSessionSeconds;
      }

      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.thumbnail,
                      width: 90,
                      height: 135,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 135,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: realProgressValue,
                          backgroundColor: Colors.grey[200],
                          color: mainColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 15),

                      Text(
                        "$displayPercent% | ${activeItem.currentPage}p",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 14, color: Colors.black87),
                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              isReadingNow
                                  ? "현재 ${_formatTime(currentSessionSeconds)} | 총 ${_formatTime(totalAccumulatedSeconds)}"
                                  : "총 ${_formatTime(totalAccumulatedSeconds)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 10),

            if (isReadingNow) ...[
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => controller.showStopDialog(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 26),
                  label: const Text(
                    "그만 읽기",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
              )
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => controller.onBookTap(book.id),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Text(
                    "독서 시작",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
              )
            ]
          ],
        ),
      );
    });
  }
}