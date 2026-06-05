import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';

class MetaInfoSection extends GetView<BookDetailController> {
  const MetaInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final book = controller.book;
      if (book.isEmpty) return const SizedBox();

      return Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey.withValues(alpha: 0.7),
          border: const Border(
            top: BorderSide(width: 0.5, color: AppColors.borderMedium),
            bottom: BorderSide(width: 0.5, color: AppColors.borderMedium),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildInfoItem("ISBN", book["isbn"] ?? ""),
              _buildInfoItem("출판일자", book["published_date"] ?? ""),
              _buildInfoItem("쪽수", "${book["total_pages"] ?? 0}쪽"),
              _buildInfoItem("카테고리", book["category"] ?? ""),
              _buildInfoItem("언어", book["language"] ?? ""),
              _buildInfoItem("출판사", book["publisher"] ?? ""),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.54,
              letterSpacing: 0.25,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.54,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}
