import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/taste_analysis_controller.dart';

class EvaluationCountCard extends GetView<TasteAnalysisController> {
  const EvaluationCountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "평가 수",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primarySurface, AppColors.primarySurface],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Obx(() => Text(
                      controller.totalReviews.value,
                      style: const TextStyle(
                        fontSize: 32, // 숫자 강조
                        fontWeight: FontWeight.w800, // 더 굵게
                        color: AppColors.primary,
                      ),
                    )),
                    const SizedBox(width: 4),
                    const Text(
                      "권",
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                  '지금까지 ${controller.userProfile['nickname'] ?? 'HECHI'}님이 읽고 평가한 책',
                  style: TextStyle(
                    fontSize: 13, // 14 -> 13 (설명글은 작게)
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}