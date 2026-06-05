import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/taste_analysis_controller.dart';

class TasteHeader extends GetView<TasteAnalysisController> {
  const TasteHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      color: AppColors.primary,
      child: Obx(() {
        final nickname = controller.userProfile['nickname'] ?? 'HECHI';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$nickname's Book",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20, // 22 -> 20 (조금 더 정돈된 느낌)
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "취향분석",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const CircleAvatar(
                  radius: 12, // 크기 살짝 축소
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          ],
        );
      }),
    );
  }
}