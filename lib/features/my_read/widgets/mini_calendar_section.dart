import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/routes.dart';
import '../controllers/my_read_controller.dart';

class MiniCalendarSection extends StatelessWidget {
  final MyReadController controller;

  const MiniCalendarSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        children: [
          // 1. 헤더 (그대로 유지)
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
                onPressed: () => controller.changeMonth(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 20),
              Text(
                '${controller.currentMonth.value}월 캘린더',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onPressed: () => controller.changeMonth(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )),

          const SizedBox(height: 25),

          // 2. 요일 표시 (그대로 유지)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((day) {
              Color dayColor = Colors.black87;
              if (day == "Sun") dayColor = Colors.red;
              if (day == "Sat") dayColor = Colors.blue;

              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: dayColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 5),

          // 3. 날짜 그리드 (그대로 유지)
          Obx(() {
            if (controller.isCalendarLoading.value) {
              return const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4DB56C)),
                ),
              );
            }
            return _buildCalendarGrid(context);
          }),

          const SizedBox(height: 30),

          // 4. 푸터: ✅ [수정] 박스형 버튼 (슬림 버전)
          InkWell(
            onTap: () => Get.toNamed(Routes.calendar),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              // ✅ [수정] 상하 패딩 축소 (14 -> 11)
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "캘린더 전체 보기",
                    style: TextStyle(
                      fontSize: 13,      // ✅ [수정] 글씨 축소 (14 -> 13)
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,           // ✅ [수정] 아이콘 축소 (18 -> 16)
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    // (기존 그리드 코드 유지)
    final year = controller.currentYear.value;
    final month = controller.currentMonth.value;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final int weekday = firstDay.weekday;
    final int startOffset = (weekday == 7) ? 0 : weekday;
    final totalDays = lastDay.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: startOffset + totalDays,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.65,
        mainAxisSpacing: 10,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        if (index < startOffset) return const SizedBox();
        final day = index - startOffset + 1;
        final hasBook = controller.calendarBooks.containsKey(day);
        final bookImageUrl = controller.calendarBooks[day];

        Color dayColor = Colors.grey[600]!;
        if (index % 7 == 0) dayColor = Colors.red;
        else if (index % 7 == 6) dayColor = Colors.blue;

        return GestureDetector(
          onTap: () {
            final books = controller.dailyBooks[day] ?? [];
            if (books.isNotEmpty) {
              _showDailyListSheet(context, day, books);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Text("$day", style: TextStyle(color: dayColor, fontSize: 13, fontWeight: FontWeight.w400)),
              const SizedBox(height: 6),
              Expanded(
                child: hasBook && bookImageUrl != null && bookImageUrl.isNotEmpty
                    ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      bookImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                    ),
                  ),
                )
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDailyListSheet(BuildContext context, int day, List<dynamic> books) {
    // (기존 바텀시트 코드 유지)
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              "${controller.currentMonth.value}월 ${day.toString().padLeft(2, '0')}일",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "${books.length} 작품을 감상했어요.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: books.isEmpty
                  ? const Center(child: Text("기록된 책이 없습니다."))
                  : ListView.separated(
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final book = books[index];
                  String title = book['title'] ?? '제목 없음';
                  String imgUrl = book['thumbnail'] ?? '';
                  String author = "작가 미상";

                  if (book['authors'] is List && (book['authors'] as List).isNotEmpty) {
                    author = book['authors'][0];
                  } else if (book['authors'] is String) {
                    author = book['authors'];
                  }

                  double rating = 0.0;
                  if (book['rating'] != null) {
                    rating = (book['rating'] is num) ? (book['rating'] as num).toDouble() : 0.0;
                  }

                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imgUrl,
                          width: 50, height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 50, height: 75, color: Colors.grey[200]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(author, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 12, color: Colors.amber),
                                  const SizedBox(width: 3),
                                  Text("$rating", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}