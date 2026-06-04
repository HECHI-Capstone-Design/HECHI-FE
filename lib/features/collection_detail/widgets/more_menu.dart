import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';
import '../../../features/collection/models/collection_list_model.dart';

class CollectionMoreMenu {
  static void show(CollectionDetailController controller) {
    if (!controller.isMine.value) return;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    const Text(
                      '컬렉션',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5, color: AppColors.border),

              // ── 삭제하기
              InkWell(
                onTap: () {
                  Get.back();
                  showDeleteDialog(controller);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 0.5, color: AppColors.border),
                    ),
                  ),
                  child: Text(
                    '삭제',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),

              // 수정하기
              InkWell(
                onTap: () async {
                  Get.back();
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
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 0.5, color: AppColors.border),
                    ),
                  ),
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static void showDeleteDialog(CollectionDetailController controller) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: 200,
          height: 107,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    '컬렉션을 삭제하시겠습니까',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: AppColors.divider),
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                          ),
                          onTap: () {
                            Get.back();
                            controller.deleteCollection();
                          },
                          child: const Center(
                            child: Text(
                              '네',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppColors.divider),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(10),
                          ),
                          onTap: () => Get.back(),
                          child: const Center(
                            child: Text(
                              '아니오',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}