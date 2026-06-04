import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthorListOverlay extends StatelessWidget {
  final List<String> authors;

  const AuthorListOverlay({super.key, required this.authors});

  @override
  Widget build(BuildContext context){
    return Container(
        height: Get.height * 0.8,
        padding: const EdgeInsets.only(bottom: 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      child: SafeArea(
        child: Column(
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: authors.length,
                separatorBuilder: (_, __) => Column(
                  children: [
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 1, color: AppColors.divider),
                    const SizedBox(height: 10),
                  ],
                ),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                    child: _buildAuthorRow(authors[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildAuthorRow(String name){
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // 프로필 아이콘
      Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: Icon(
              Icons.person,
              color: Colors.white,
              size: 35
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
    ],
  );
}
