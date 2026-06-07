import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';
import '../../../features/collection/models/collection_list_model.dart';
import 'package:hechi/core/widgets/user_avatar.dart';

class CollectionInfoSection extends StatelessWidget {
  final CollectionDetailController controller;

  const CollectionInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 작성자 프로필
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  buildUserAvatar(controller.creatorProfileImageUrl.value, 20),
                  const SizedBox(width: 10),
                  Text(
                    controller.creatorName.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              if (controller.isMine.value)
                OutlinedButton(
                  onPressed: () async {
                    final item = CollectionListItem(
                      id: controller.collectionId.toString(),
                      title: controller.collectionTitle.value,
                      description: controller.collectionDesc.value,
                      authorName: controller.creatorName.value,
                      tags: List<String>.from(controller.tags),
                      bookCoverUrls: List<String>.from(controller.thumbnailCovers),
                      likeCount: controller.likeCount.value,
                      bookCount: controller.books.length,
                      isLiked: controller.isLiked.value,
                      isPublic: !controller.isPrivate.value,
                    );
                    final result = await Get.toNamed('/create_collection', arguments: item);
                    if (result != null) {
                      controller.fetchDetail(modified: true);
                    };
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                    side: const BorderSide(color: AppColors.primaryLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text(
                    '수정하기',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 제목
          Text(
            controller.collectionTitle.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // ── 설명
          if (controller.collectionDesc.value.isNotEmpty) ...[
            Text(
              controller.collectionDesc.value,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
            if (controller.tags.isNotEmpty) const SizedBox(height: 16),
          ],

          // ── 태그
          if (controller.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: ShapeDecoration(
                  color: AppColors.border.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.79,
                  ),
                ),
              )).toList(),
            ),
        ],
      )),
    );
  }
}