import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/book_detail_controller.dart';

class MoreMenuOverlay extends StatelessWidget {
  const MoreMenuOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookDetailController>();

    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            /*
          Obx(() {
            final bool hasRated = controller.myRating.value > 0.0;

            return menuItem(
              hasRated ? "본 날짜 수정" : "본 날짜 추가",
              hasRated ? Icons.calendar_month : Icons.event,
              onTap: () {
                print(hasRated ? "날짜 수정" : "날짜 추가");
              },
            );
          }),
          */
            menuItem("관심없어요", Icons.remove_circle_outline, onTap: () {
              controller.onNotInterested();
            }),
          ],
        ),
      ),
    );
  }

  Widget menuItem(String label, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: () {
        if (onTap != null) onTap();
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: const BoxDecoration(
          border:
          Border(bottom: BorderSide(color: AppColors.borderMedium, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Icon(icon, size: 22, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}