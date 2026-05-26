import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_read_controller.dart';

class ActivityStats extends StatelessWidget {
  final MyReadController controller;

  const ActivityStats({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(controller.totalReviews.value, "평가")),
          Container(width: 1, height: 24, color: const Color(0xFFEEEEEE)),
          Expanded(child: _buildStatItem(controller.totalComments.value, "코멘트")),
          Container(width: 1, height: 24, color: const Color(0xFFEEEEEE)),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Get.toNamed('/collection_list');
                controller.collectionRefreshKey.value++;
              },
              child: _buildStatItem(controller.totalCollections.value, "컬렉션"),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
            count,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3F3F3F)
            )
        ),
        const SizedBox(height: 4),
        Text(
            label,
            style: const TextStyle(
                fontSize: 13, // ✅ 다른 통계 라벨과 크기 통일
                color: Colors.grey
            )
        ),
      ],
    );
  }
}