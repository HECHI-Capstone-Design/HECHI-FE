import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/taste_analysis_controller.dart';

class PreferredGenreList extends GetView<TasteAnalysisController> {
  const PreferredGenreList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "독서 선호 장르",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F3F3F),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.genreRankings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.menu_book_rounded,
                          size: 50,
                          color: Color(0xFFAAD2B6) // 연한 초록색 테마
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "아직 분석할 독서 데이터가 없어요! 🥲",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3F3F)
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "다 읽은 책에 별점을 남기고\n나만의 독서 취향을 정확하게 알아보세요!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.4
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final top3 = controller.genreRankings.take(3).toList();
            final others = controller.genreRankings.skip(3).toList();

            String to100Score(double score5) => (score5 * 20).round().toString();

            return Column(
              children: [
                const Center(
                  child: Text(
                    "인생은 역시 한 편의 책!",
                    style: TextStyle(
                      color: Color(0xFF4DB56C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Top 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: top3.map((e) => Column(
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F3F3F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${to100Score(e.average5)}점 - ${e.reviewCount}편",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  )).toList(),
                ),
                const SizedBox(height: 30),

                // 나머지 리스트
                ...others.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3F3F3F),
                        ),
                      ),
                      Text(
                        "${to100Score(e.average5)}점 - ${e.reviewCount}편",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            );
          }),
        ],
      ),
    );
  }
}