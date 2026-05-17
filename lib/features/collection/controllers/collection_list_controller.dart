import 'package:get/get.dart';
import '../models/collection_list_model.dart';

class CollectionListController extends GetxController {
  final RxList<CollectionListItem> collections = <CollectionListItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCollections();
  }

  Future<void> loadCollections() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: Replace dummy data with API response
    collections.assignAll(dummyCollections);
    // collections.assignAll([]);
    isLoading.value = false;
  }

  void toggleLike(String collectionId) {
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index == -1) return;

    final item = collections[index];
    collections[index] = item.copyWith(isLiked: !item.isLiked);

    // TODO: Replace dummy data with API response
    // Call API: POST /collections/{id}/like or DELETE /collections/{id}/like
  }

  void navigateToCreateCollection() async {
    final result = await Get.toNamed('/create_collection');

    if (result != null && result is Map<String, dynamic>) {
      // TODO: Replace dummy data with API response
      // 실제로는 POST /collections 응답에서 생성된 컬렉션 데이터를 받아야 함
      final newCollection = CollectionListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result['title'] ?? '',
        description: result['description'] ?? '',
        authorName: '나', // TODO: 실제 사용자 이름으로 교체
        tags: List<String>.from(result['tags'] ?? []),
        bookCoverUrls: [],
        likeCount: 0,
        bookCount: (result['bookIds'] as List?)?.length ?? 0,
        isLiked: false,
        isPublic: !(result['isPrivate'] ?? false),
      );

      collections.insert(0, newCollection);
    }
  }

  void navigateToCollectionDetail(String collectionId) {
    Get.toNamed('/collection_detail', arguments: collectionId);
  }
}
