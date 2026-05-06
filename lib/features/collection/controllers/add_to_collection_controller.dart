import 'package:get/get.dart';
import '../models/collection_list_model.dart';
import '../models/collection_book_model.dart';

class AddToCollectionController extends GetxController {
  late final int bookId;

  final RxList<CollectionListItem> collections = <CollectionListItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<String> selectedCollectionIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    bookId = (args != null && args is int) ? args : -1;
    loadMyCollections();
  }

  Future<void> loadMyCollections() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Replace dummy data with API response - GET /collections/my
    collections.assignAll(dummyCollections);
    isLoading.value = false;
  }

  void toggleCollection(String collectionId) {
    if (selectedCollectionIds.contains(collectionId)) {
      selectedCollectionIds.remove(collectionId);
    } else {
      selectedCollectionIds.add(collectionId);
    }
  }

  bool isSelected(String collectionId) =>
      selectedCollectionIds.contains(collectionId);

  void navigateToCreateCollection() {
    final book = CollectionBook(
      id: bookId.toString(),
      title: '',
      author: '',
    );
    Get.toNamed('/create_collection', arguments: book);
  }

  void onConfirm() {
    // TODO: Replace dummy data with API response
    // POST /collections/{id}/books for each selected
    Get.back(result: selectedCollectionIds.toList());
  }

  void onCancel() => Get.back();
}