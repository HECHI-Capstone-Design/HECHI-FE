import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_list_controller.dart';
import '../widgets/collection_card.dart';

class CollectionListPage extends GetView<CollectionListController> {
  const CollectionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F3F3F)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '컬렉션',
          style: TextStyle(
            color: Color(0xFF3F3F3F),
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            height: 1.75,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: GestureDetector(
              onTap: controller.navigateToCreateCollection,
              child: const Center(
                child: Text(
                  '새 컬렉션',
                  style: TextStyle(
                    color: Color(0xFF4DB56C),
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
          child: Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
        ),
      ),
      body: _buildBody(),
    );
  }

  // ── 바디 ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4DB56C)),
        );
      }

      if (controller.collections.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        itemCount: controller.collections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final collection = controller.collections[index];
          return CollectionCard(
            collection: collection,
            onTap: () => controller.navigateToCollectionDetail(collection.id),
            onLikeTap: () => controller.toggleLike(collection.id),
          );
        },
      );
    });
  }

  // ── 빈 상태 ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.collections_bookmark_outlined,
              size: 60, color: Color(0xFFDADADA)),
          const SizedBox(height: 16),
          const Text(
            '아직 컬렉션이 없습니다.',
            style: TextStyle(
              color: Color(0xFF717171),
              fontSize: 15,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: controller.navigateToCreateCollection,
            child: const Text(
              '첫 컬렉션 만들기',
              style: TextStyle(
                color: Color(0xFF4DB56C),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF4DB56C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}