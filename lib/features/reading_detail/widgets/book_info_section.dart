import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reading_detail_controller.dart';

class BookInfoSection extends GetView<ReadingDetailController> {
  const BookInfoSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 24, 17, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
            controller.bookTitle.value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: 0.10,
            ),
          )),
          const SizedBox(height: 18),

          Obx(() => Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${controller.authorName.value} 지음'),
                const TextSpan(text: ' · '),
                TextSpan(text: '${controller.translatorName.value} 옮김'),
              ],
            ),
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 15,
              fontFamily: 'Roboto',
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          )),
          const SizedBox(height: 8),

          Obx(() => Text(
            '${controller.category.value} · ${controller.publishDate.value}',
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 15,
              fontFamily: 'Roboto',
              height: 1.4,
              fontWeight: FontWeight.w300,
            ),
          )),
        ],
      ),
    );
  }
}