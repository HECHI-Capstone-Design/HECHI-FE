import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';

class BookInfoSection extends GetView<BookDetailController> {
  const BookInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final book = controller.book;
      if (book.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
            child: Text(
              book["title"] ?? "",
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                // height: 0.71,
                height: 1.3,
                letterSpacing: 0.10,
              ),
            ),
          ),

          // 평점
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
            child: Row(
              children: [
                /*
                if (book.expectedRating > 0) ...[
                  Text(
                    '예상★${book.expectedRating}',
                    style: const TextStyle(
                      color: AppColors.primary, // TextIcon-OnNormal-Primary
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.54,
                      letterSpacing: 0.25,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                */
                // 평균 평점
                Text(
                  '평균★${(book["average_rating"] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textMedium, // TextIcon-OnNormal-NormalMidEmp
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.54,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}