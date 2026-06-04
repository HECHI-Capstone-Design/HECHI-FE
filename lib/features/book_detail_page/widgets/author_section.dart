import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';
import '../widgets/overlays/author_list_overlay.dart';

class AuthorSection extends GetView<BookDetailController> {
  const AuthorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authors = List<String>.from(controller.book["authors"] ?? []);

    final displayAuthors = authors.isEmpty ? ["작가 미상"] : authors;
    final hasMoreAuthors = displayAuthors.length >= 3;
    final visibleAuthors = hasMoreAuthors ? displayAuthors.take(2).toList() : displayAuthors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: const Text(
            '저자/역자',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.25,
            ),
          ),
        ),

        // 작가 리스트 생성
        Column(
          children: List.generate(visibleAuthors.length, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              child: _buildAuthorRow(visibleAuthors[index]),
            );
          }),
        ),
        // 모아보기 버튼
        if (hasMoreAuthors)
          InkWell(
            onTap: () {
              Get.bottomSheet(
                AuthorListOverlay(authors: displayAuthors),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(width: 1, color: AppColors.borderMedium),
                  bottom: BorderSide(width: 1, color: AppColors.borderMedium),
                ),
              ),
              child: const Text(
                '모두보기',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }
}

Widget _buildAuthorRow(String name){
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // 프로필 아이콘
      Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: Icon(
              Icons.person,
              color: Colors.white,
              size: 40
          ),
        ),
      ),
      const SizedBox(width: 20),

      // 텍스트 정보
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.33,
              ),
            ),
            const SizedBox(height: 2),
            const Text('작가',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                  height: 1.33,
                )
            ),
          ],
        ),
      ),

      // 화살표
      /*
      const Icon(
        Icons.arrow_forward_ios,
        size: 20,
        color: AppColors.textMedium,
      ),
       */
    ],
  );
}
