import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';

class ActionButtons extends GetView<BookDetailController> {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      child: Obx(
            () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBtn(
              icon: Icons.add,
              label: "읽고싶어요",
              isActive: controller.isWishlisted.value,
              onTap: controller.onWantToRead,
            ),
            _buildBtn(
              icon: Icons.edit,
              label: "코멘트",
              isActive: controller.isCommented.value,
              onTap: controller.onWriteReview,
            ),
            /*
            _buildBtn(
              icon: Icons.remove_red_eye,
              label: controller.readingStatus.value == "COMPLETED"
                  ? "완독함"
                  : "읽는 중",
              isActive: controller.readingStatus.value == "READING" ||
                  controller.readingStatus.value == "COMPLETED",
              onTap: controller.onReadingStatus,
            ),
             */
            _buildBtn(
              icon: Icons.notes,
              label: '독서 기록',
              isActive: false,
              onTap: () => Get.toNamed('/book_note', arguments: {
                'bookId': controller.bookId,
                'tabIndex': 0,
              }),
            ),
            _buildBtn(
              icon: Icons.library_add_outlined,
              label: '컬렉션',
              isActive: false,
              onTap: () async {
                await Get.toNamed('/collection/add', arguments: controller.bookId);
                controller.collectionRefreshTrigger.value++;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final Color activeColor = AppColors.primary;
    final Color disabledColor = AppColors.textHint;
    final Color disabledTextColor = AppColors.textMedium;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        constraints: const BoxConstraints(minWidth: 70, minHeight: 51),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(
              icon,
              size: 25,
              color: isActive ? activeColor : disabledColor,
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? activeColor : disabledTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.33,
                letterSpacing: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}