import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_read_controller.dart';
import '../../taste_analysis/widgets/star_rating_chart.dart';

class TasteAnalysisPreview extends StatelessWidget {
  final MyReadController controller;

  const TasteAnalysisPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // ✅ 공통 위젯 사용!
            StarRatingChart(
              ratingData: controller.ratingDistData,
              mostGivenRating: controller.mostGivenRating.value,
            ),

            const SizedBox(height: 30),


            Row(
              children: [
                // 1. 별점 평균 (1/3 공간 차지)
                Expanded(
                  child: _buildBottomStatItem(controller.averageRating.value, "별점 평균"),
                ),

                // 구분선
                Container(width: 1, height: 30, color: AppColors.divider),

                // 2. 별점 개수 (1/3 공간 차지)
                Expanded(
                  child: _buildBottomStatItem(controller.totalReviews.value, "별점 개수"),
                ),

                // 구분선
                Container(width: 1, height: 30, color: AppColors.divider),

                // 3. 많이 준 별점 (1/3 공간 차지)
                Expanded(
                  child: _buildBottomStatItem(controller.mostGivenRating.value, "많이 준 별점"),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomStatItem(String value, String label) {
    return Column(
      children: [
        Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark
            )
        ),
        const SizedBox(height: 6),
        Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.grey
            )
        ),
      ],
    );
  }
}