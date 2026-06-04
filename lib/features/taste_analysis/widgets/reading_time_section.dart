import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/taste_analysis_controller.dart';

class ReadingTimeSection extends GetView<TasteAnalysisController> {
  const ReadingTimeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "독서 감상 시간",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Obx(() => RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15, // 16 -> 15 (본문 크기 통일)
                  color: AppColors.textDark, // 완전 검정보다 부드러운 검정
                  height: 1.4, // 줄 간격 확보
                ),
                children: [
                  const TextSpan(text: "총 "),
                  TextSpan(
                    text: controller.totalReadingTime.value,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // 숫자만 살짝 키움
                    ),
                  ),
                  const TextSpan(text: " 동안 감상하셨습니다."),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }
}