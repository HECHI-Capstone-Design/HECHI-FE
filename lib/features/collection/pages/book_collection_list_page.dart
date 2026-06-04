import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_collection_list_controller.dart';
import '../widgets/collection_thumbnail.dart';

class BookCollectionListPage extends GetView<BookCollectionListController> {
  const BookCollectionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '이 도서가 담긴 컬렉션',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 2;
            const crossAxisSpacing = 15.0;
            const padding = 17.0;
            const itemPadding = 15.0;

            final itemWidth = (constraints.maxWidth - padding * 2 - crossAxisSpacing) / crossAxisCount;
            final thumbnailWidth = itemWidth - itemPadding * 2;
            final thumbnailHeight = thumbnailWidth * 3 / 2;
            const textHeight = 10 + 36 + 10 + 18 + 10;
            final itemHeight = thumbnailHeight + textHeight + itemPadding * 2;
            final childAspectRatio = itemWidth / itemHeight;

            return GridView.builder(
              padding: const EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: 15,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: controller.collections.length,
              itemBuilder: (context, index) {
                final collection = controller.collections[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Get.toNamed(
                      '/collection_detail',
                      arguments: int.tryParse(collection.id),
                    );
                    controller.loadCollections();
                    if (result != null && result is Map<String, dynamic> && result['updated'] == true) {
                      controller.loadCollections();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(itemPadding),
                    decoration: ShapeDecoration(
                      color: AppColors.border.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CollectionThumbnail(
                          bookCoverUrls: collection.bookCoverUrls,
                          width: thumbnailWidth,
                          height: thumbnailHeight,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          collection.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 1.29,
                            letterSpacing: 0.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '좋아요 ${collection.likeCount}',
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 13,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 1.38,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}