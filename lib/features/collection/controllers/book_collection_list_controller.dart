import 'package:get/get.dart';
import '../models/collection_list_model.dart';

class BookCollectionListController extends GetxController {
  final RxList<CollectionListItem> collections = <CollectionListItem>[].obs;
  final RxBool isLoading = false.obs;

  late int bookId;

  @override
  void onInit() {
    super.onInit();
    bookId = Get.arguments ?? -1;
    loadCollections();
  }

  Future<void> loadCollections() async {
    isLoading.value = true;

    // TODO: Replace dummy data with API response
    // GET /collections?book_id={bookId}
    await Future.delayed(const Duration(milliseconds: 300));
    collections.assignAll(dummyCollections);

    isLoading.value = false;
  }

  void toggleLike(String collectionId) {
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index == -1) return;
    final item = collections[index];
    collections[index] = item.copyWith(isLiked: !item.isLiked);

    // TODO: Replace dummy data with API response
    // POST /collections/{id}/like or DELETE /collections/{id}/like
  }
}