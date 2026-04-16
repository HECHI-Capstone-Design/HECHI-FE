import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/collection_tag_model.dart';
import '../models/collection_book_model.dart';
import '../models/collection_list_model.dart';

class CreateCollectionController extends GetxController {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final tagSearchController = TextEditingController();

  final RxBool isPrivate = false.obs;
  final RxList<CollectionTag> selectedTags = <CollectionTag>[].obs;
  final RxList<CollectionBook> selectedBooks = <CollectionBook>[].obs;
  final RxString description = ''.obs;

  final RxString selectedCategory = '장르'.obs;
  final RxString tagSearchQuery = ''.obs;
  final RxBool isTagSearchActive = false.obs;

  final RxBool isEditMode = false.obs;
  String? editingCollectionId;

  final List<TagCategory> categories = allTagCategories;

  @override
  void onInit() {
    super.onInit();

    tagSearchController.addListener(() {
      tagSearchQuery.value = tagSearchController.text;
      isTagSearchActive.value = tagSearchController.text.isNotEmpty;
    });

    descriptionController.addListener(() {
      description.value = descriptionController.text;
    });

    final args = Get.arguments;
    if (args == null){ } // 컬렉션 리스트 -> 새 컬렉션
    else if (args is CollectionBook) { // 도서 상세에서 넘어온 경우 해당 도서 자동 추가
      selectedBooks.add(args);
    }
    else if (args is CollectionListItem) { // 수정 모드
      // TODO: Replace dummy data with API response
      isEditMode.value = true;
      editingCollectionId = args.id;
      titleController.text = args.title;
      descriptionController.text = args.description;
      description.value = args.description;
      isPrivate.value = !args.isPublic;

      final allTags = allTagCategories.expand((c) => c.tags).toList();
      for (final label in args.tags) {
        final match = allTags.firstWhereOrNull((t) => t.label == label);
        if (match != null) selectedTags.add(match);
      }
      // 도서 목록은 API에서 별도로 받아와야 함
      // TODO: Replace dummy data with API response
      // GET /collections/{id}/books
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    tagSearchController.dispose();
    super.onClose();
  }

  // ── Tag 관련 ───────────────────────────────────────────────────────────────
  List<CollectionTag> get currentCategoryTags {
    return categories
        .firstWhereOrNull((c) => c.name == selectedCategory.value)
        ?.tags ??
        [];
  }

  List<CollectionTag> get filteredSearchTags {
    final query = tagSearchQuery.value.toLowerCase();
    if (query.isEmpty) return [];
    return categories
        .expand((c) => c.tags)
        .where((t) => t.label.toLowerCase().contains(query))
        .toList();
  }

  void selectCategory(String name) => selectedCategory.value = name;

  void toggleTag(CollectionTag tag) {
    if (isTagSelected(tag)) {
      selectedTags.removeWhere((t) => t.label == tag.label);
    } else {
      selectedTags.add(tag);
    }
  }

  bool isTagSelected(CollectionTag tag) =>
      selectedTags.any((t) => t.label == tag.label);

  void removeTag(CollectionTag tag) =>
      selectedTags.removeWhere((t) => t.label == tag.label);

  void clearTagSearch() {
    tagSearchController.clear();
    isTagSearchActive.value = false;
  }

  // ── Book 관련 ──────────────────────────────────────────────────────────────
  void addBook(CollectionBook book) {
    if (!selectedBooks.any((b) => b.id == book.id)) {
      selectedBooks.add(book);
    }
  }

  void removeBook(String bookId) =>
      selectedBooks.removeWhere((b) => b.id == bookId);

  // ── 확인 / 취소 ────────────────────────────────────────────────────────────
  bool get isFormValid => titleController.text.trim().isNotEmpty;

  void onConfirm() {
    if (!isFormValid) {
      Get.snackbar(
        '입력 오류',
        '컬렉션 제목을 입력해주세요.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    // TODO: Replace dummy data with API response
    // POST /collections
    final payload = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'isPrivate': isPrivate.value,
      'tags': selectedTags.map((t) => t.label).toList(),
      'bookIds': selectedBooks.map((b) => b.id).toList(),
    };
    if (isEditMode.value) {
      // TODO: Replace dummy data with API response
      // PATCH /collections/{editingCollectionId}
      debugPrint('Editing collection $editingCollectionId: $payload');
    } else {
      // TODO: Replace dummy data with API response
      // POST /collections
      debugPrint('Creating collection: $payload');
    }
    Get.back(result: payload);
  }

  void onCancel() => Get.back();

  // ── 도서 검색 페이지 이동 ──────────────────────────────────────────────────
  void navigateToBookSearch() async {
    final result = await Get.toNamed(
      '/collection/book_edit',
      arguments: List<CollectionBook>.from(selectedBooks),
    );
    if (result != null && result is List<CollectionBook>) {
      selectedBooks.assignAll(result); // 결과 반영
    }
  }
}