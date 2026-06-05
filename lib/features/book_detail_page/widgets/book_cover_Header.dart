import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';

class BookCoverHeader extends GetView<BookDetailController> {
  const BookCoverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final book = controller.book;
    final coverUrl = book["thumbnail"] ?? "";

    return Stack(
      children: [
        // ====== 이미지 영역 ======
        Container(
          width: double.infinity,
          height: 200,
          color: AppColors.backgroundGrey,
          child: coverUrl.isNotEmpty
              ? Image.network(
            coverUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          )
              : const Center(child: Icon(Icons.book, size: 50, color: Colors.grey)),
        ),

        // ====== 상단 어두운 그라데이션 ======
        Container(
          height: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54,
                Colors.transparent,
              ],
            ),
          ),
        ),

        // ====== 하단 흰색 그라데이션 ======
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
