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

  void navigateToCreateCollection() {
    // TODO: 생성 페이지 라우트 연결
    Get.toNamed('/create_collection');
  }

  void navigateToCollectionDetail(String collectionId) {
    // TODO: 상세 페이지 라우트 연결
    Get.toNamed('/collection_detail', arguments: collectionId);
  }
}