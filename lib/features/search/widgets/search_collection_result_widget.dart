import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart';
import '../../collection/widgets/collection_card.dart';

class SearchCollectionResultWidget extends GetView<BookSearchController> {
  const SearchCollectionResultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isCollectionLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black),
        );
      }

      if (controller.collectionSearchResults.isEmpty) {
        return const Center(
          child: Text(
            '검색 결과와 일치하는 컬렉션이 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        itemCount: controller.collectionSearchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          return Obx(() {
            final collection = controller.collectionSearchResults[index];
            return CollectionCard(
              collection: collection,
              onTap: () async {
                await Get.toNamed(
                  '/collection_detail',
                  arguments: int.tryParse(collection.id),
                );
                controller.searchCollectionsWithFilter();
              },
              onLikeTap: () => controller.toggleCollectionLike(collection.id),
            );
          });
        },
      );
    });
  }
}