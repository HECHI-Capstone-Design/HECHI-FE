import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/add_to_collection_controller.dart';
import '../models/collection_list_model.dart';
import '../widgets/collection_thumbnail.dart';

class AddToCollectionPage extends GetView<AddToCollectionController> {
  const AddToCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          '내 컬렉션에 추가',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            height: 1.75,
          ),
        ),
        leading: GestureDetector(
          onTap: controller.onCancel,
          child: const Center(
            child: Text(
              '취소',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.87,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: GestureDetector(
              onTap: controller.onConfirm,
              child: const Center(
                child: Text(
                  '확인',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.87,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.5, color: AppColors.border),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return ListView(
          children: [
            _buildNewCollectionItem(),
            const Divider(
              height: 1,
              thickness: 0.5,
              indent: 20,
              endIndent: 20,
              color: AppColors.border,
            ),
            ...controller.collections.map((collection) {
              return Column(
                children: [
                  _buildCollectionItem(collection),
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 20,
                    endIndent: 20,
                    color: AppColors.border,
                  ),
                ],
              );
            }),
          ],
        );
      }),
    );
  }

  // ── 새 컬렉션 아이템 ──────────────────────────────────────────────────────
  Widget _buildNewCollectionItem() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.navigateToCreateCollection,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 126,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 1,
                    color: AppColors.textHint,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 30,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 20),
            const Text(
              '새 컬렉션',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.56,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 컬렉션 아이템 ─────────────────────────────────────────────────────────
  Widget _buildCollectionItem(CollectionListItem collection) {
    return Obx(() {
      final isSelected = controller.isSelected(collection.id);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.toggleCollection(collection.id),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 15,
            left: 20,
            right: 20,
            bottom: 15,
          ),
          child: Row(
            children: [
              CollectionThumbnail(
                bookCoverUrls: collection.bookCoverUrls,
                width: 84,
                height: 126,
              ),
              const SizedBox(width: 20),
              // 컬렉션 제목
              Expanded(
                child: Text(
                  collection.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.11,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              isSelected
                  ? const Icon(
                Icons.check_circle,
                size: 23,
                color: AppColors.primary,
              )
                  : const Icon(
                Icons.check_circle_outline,
                size: 23,
                color: AppColors.border,
              ),
            ],
          ),
        ),
      );
    });
  }
}