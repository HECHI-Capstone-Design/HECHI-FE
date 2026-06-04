import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';
import '../../review_list/widgets/review_card.dart';

class CommentSection extends GetView<BookDetailController> {
  const CommentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allReviews = controller.reviews;
      final int commentCount = allReviews.where((r) {
        final content = (r['content'] ?? '').toString();
        return content.trim().isNotEmpty;
      }).length;

      final hasMoreToReviews = commentCount > 3;

      final bestReviews = controller.bestReviews;

      // 그래프 데이터
      final histogram = Map<String, dynamic>.from(controller.book["rating_histogram"] ?? {});
      final maxCount = controller.maxRatingCount.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 타이틀
          Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              alignment: Alignment.centerLeft,
              child: Row(
                  children: [
                    const Text('코멘트', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text("$commentCount", style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w400)),
                  ]
              )
          ),

          // 2. 평점 그래프
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(17, 20, 17, 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey.withValues(alpha: 0.7),
              border: Border(
                bottom: BorderSide(width: 0.5, color: AppColors.borderMedium),
                top: BorderSide(width: 0.5, color: AppColors.borderMedium),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('평균 평점', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${(controller.book["average_rating"] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 40),
                Expanded(child: _buildRatingGraph(histogram, maxCount)),
              ],
            ),
          ),

          // 3. 리뷰 리스트
          if (commentCount == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 35),
              decoration: const BoxDecoration(
                color: AppColors.backgroundGrey,
              ),
              child: const Center(child: Text("첫 번째 리뷰를 남겨보세요!", style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: bestReviews.length, // 최대 3개

              itemBuilder: (_, index) {
                return Obx(() {
                  final r = controller.bestReviews[index];

                  return ReviewCard(
                    key: ValueKey('${r['id']}_${r['is_liked']}_${r['like_count']}'),
                    review: r,
                    type: ReviewCardType.simple,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                    onLikeToggle: (int id) => controller.toggleLike(id),
                  );
                });
              }
            ),

          // 4. 모두보기 버튼
          if (hasMoreToReviews)
            InkWell(
              onTap: () => Get.toNamed("/review_list", arguments: controller.bookId), // ✅ 전체 페이지 이동
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(width: 1, color: AppColors.borderMedium),
                    bottom: BorderSide(width: 1, color: AppColors.borderMedium),
                  ),
                ),
                child: const Text('모두보기', style: TextStyle(color: Colors.black, fontSize: 15)),
              ),
            ),
        ],
      );
    });
  }
}

// 그래프 생성
Widget _buildRatingGraph(Map<String, dynamic> histogram, int maxCount) {
  final List<double> scores = List.generate(10, (index) => 0.5 + (index * 0.5));

  final List<Map<String, dynamic>> sortedData = scores.map((score) {
    final int count = histogram[score.toString()] ?? 0;
    final double ratio = maxCount > 0 ? count / maxCount : 0.0;
    return {'score': score, 'ratio': ratio};
  }).toList();
  sortedData.sort((a, b) => (a['score'] as num).compareTo(b['score'] as num));

  double maxRatio = 0.0;
  for (var d in sortedData) {
    double r = (d['ratio'] as num).toDouble();
    if (r > maxRatio) maxRatio = r;
  }

  final Color DarkGreen = AppColors.primary;
  final Color LightGreen = AppColors.primaryLight;
  const double maxHeight = 100.0;

  return SizedBox(
    height: 140,
    child: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedData.asMap().entries.map((entry) {
          final int idx = entry.key;
          final double ratio = (entry.value['ratio'] as num).toDouble();
          final double score = (entry.value['score'] as num).toDouble();

          final bool isMax = (ratio == maxRatio && ratio > 0);

          Color barColor = isMax ? DarkGreen : LightGreen;
          if (ratio == 0) barColor = AppColors.backgroundGrey;

          double barHeight = 2.0;
          if (maxRatio > 0 && ratio > 0) {
            barHeight = (ratio / maxRatio) * maxHeight;
          }

          final bool showLabel = isMax || idx == 0 || idx == sortedData.length - 1;
          final String scoreText = score % 1 == 0
              ? score.toInt().toString()
              : score.toStringAsFixed(1);


          return Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showLabel) ...[
                    Text(
                      scoreText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: false,
                    ),
                    const SizedBox(height: 4),
                  ] else
                    const SizedBox(height: 18),

                  SizedBox(
                    height: barHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}