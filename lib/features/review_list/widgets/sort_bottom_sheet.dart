import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/review_list_controller.dart';

class SortBottomSheet extends GetView<ReviewListController> {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15,),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 0.5, color: AppColors.borderMedium),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '정렬',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // 2. 옵션 리스트
            _buildOption("좋아요 순", "likes"),
            _buildOption("최신 순", "latest"),
            const SizedBox(height: 30,),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String label, String value) {
    return InkWell(
      onTap: () => controller.changeSort(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0.5,
              color: AppColors.borderMedium,
            ),
          ),
        ),
        child: Obx(() {
          final bool isSelected = controller.currentSort.value == value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check,
                  size: 22,
                  color: AppColors.primary,
                ),
            ],
          );
        }),
      ),
    );
  }
}