import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/colors.dart';
import '../controllers/reward_controller.dart';
import '../widgets/badge_item_widget.dart';

class RewardPage extends GetView<RewardController> {
  const RewardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color whiteBg = Colors.white;
    

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: whiteBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 22),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '리워드',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      // 🚀 핵심 1: SafeArea로 감싸서 기기 하단 홈버튼(소프트키/인디케이터) 영역 침범 차단
      body: SafeArea(
        bottom: true,
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return GridView.builder(
            // 🚀 핵심 2: 맨 밑에 있는 배지가 바닥에 딱 붙지 않도록 bottom 패딩 40 부여
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 40),
            itemCount: controller.rxBadges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 24,
              childAspectRatio: 0.75, // (비율 아주 좋습니다!)
            ),
            itemBuilder: (context, index) {
              final badge = controller.rxBadges[index];
              return BadgeItemWidget(badge: badge);
            },
          );
        }),
      ),
    );
  }
}