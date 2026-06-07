import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/taste_analysis_controller.dart';
import 'package:hechi/app/controllers/app_controller.dart';
import 'package:hechi/core/widgets/user_avatar.dart';

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
                fontSize: 20,
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
                Obx(() {
                  final appController = Get.find<AppController>();
                  return buildUserAvatar(
                    appController.userProfile['profileImageUrl']?.toString(),
                    20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18g,
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