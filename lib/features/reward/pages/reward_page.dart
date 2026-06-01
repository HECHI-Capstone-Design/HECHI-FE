import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reward_controller.dart';
import '../widgets/badge_item_widget.dart';

class RewardPage extends GetView<RewardController> {
  const RewardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color whiteBg = Colors.white;
    const Color textColor = Color(0xFF232725);

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: whiteBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 22),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '리워드',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5CBA74)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: controller.rxBadges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,         
            crossAxisSpacing: 20,
            mainAxisSpacing: 24,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final badge = controller.rxBadges[index];
            return BadgeItemWidget(badge: badge);
          },
        );
      }),
    );
  }
}