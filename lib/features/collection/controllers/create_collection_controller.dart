import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/collection_tag_model.dart';
import '../models/collection_book_model.dart';
import '../models/collection_list_model.dart';

class CreateCollectionController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final tagSearchController = TextEditingController();

  final RxBool isPrivate = false.obs;
  final RxList<CollectionTag> selectedTags = <CollectionTag>[].obs;
  final RxList<CollectionBook> selectedBooks = <CollectionBook>[].obs;
  final RxString description = ''.obs;

  final RxString selectedCategory = ''.obs;
  final RxString tagSearchQuery = ''.obs;
  final RxBool isTagSearchActive = false.obs;
  final RxBool isTagDropdownOpen = false.obs;
  final RxBool isLoading = false.obs;

  final RxBool isEditMode = false.obs;
  int? editingCollectionId;

  final RxList<TagCategory> categories = <TagCategory>[].obs;
  final RxList<CollectionTag> popularTags = <CollectionTag>[].obs;

  String? get _token => box.read('access_token');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

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

    fetchCategories();
    fetchPopularTags();

    final args = Get.arguments;
    if (args == null) {
    } else if (args is CollectionBook) {
      selectedBooks.add(args);
    } else if (args is CollectionListItem) {
      isEditMode.value = true;
      editingCollectionId = int.tryParse(args.id);
      titleController.text = args.title;
      descriptionController.text = args.description;
      description.value = args.description;
      isPrivate.value = !args.isPublic;
      _pendingTagLabels = List<String>.from(args.tags);
      _fetchCollectionBooks(editingCollectionId!);
    }
  }

  List<String> _pendingTagLabels = [];

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    tagSearchController.dispose();
    super.onClose();
  }

  // ── Tag 관련 ───────────────────────────────────────────────────────────────
  Future<void> fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tags/categories'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['categories'] as List)
            .map((e) => TagCategory.fromJson(e))
            .toList();
        categories.assignAll(list);

        for (final cat in list) {
          await fetchTagsByCategory(cat);
        }

        if (_pendingTagLabels.isNotEmpty) {
          final allTags = categories.expand((c) => c.tags).toList();
          for (final label in _pendingTagLabels) {
            final match = allTags.firstWhereOrNull((t) => t.label == label);
            if (match != null) selectedTags.add(match);
          }
          _pendingTagLabels = [];
        }
      }
    } catch (e) {
      print('❌ fetchCategories error: $e');
    }
  }

  Future<void> fetchTagsByCategory(TagCategory category) async {
    try {
      final uri = Uri.parse('$baseUrl/tags').replace(queryParameters: {
        'category': category.name,
        'limit': '100',
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        category.tags = (data['tags'] as List)
            .map((e) => CollectionTag.fromJson(e))
            .toList();
        categories.refresh();
      }
    } catch (e) {
      print('❌ fetchTagsByCategory error: $e');
    }
  }

  Future<void> fetchPopularTags() async {
    try {
      final uri = Uri.parse('$baseUrl/tags').replace(queryParameters: {
        'limit': '5',
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final tags = (data['tags'] as List)
            .map((e) => CollectionTag.fromJson(e))
            .toList();
        popularTags.assignAll(tags);
      }
    } catch (e) {
      print('❌ fetchPopularTags error: $e');
    }
  }

  Future<List<CollectionTag>> searchTags(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/tags').replace(queryParameters: {
        'query': query,
        'limit': '30',
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return (data['tags'] as List)
            .map((e) => CollectionTag.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('❌ searchTags error: $e');
    }
    return [];
  }

  List<CollectionTag> get currentCategoryTags {
    return categories
        .firstWhereOrNull((c) => c.name == selectedCategory.value)
        ?.tags ?? [];
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

  void openTagDropdown() => isTagDropdownOpen.value = true;

  void closeTagDropdown() {
    isTagDropdownOpen.value = false;
    selectedCategory.value = '';
    clearTagSearch();
  }

  // ── Book 관련 ──────────────────────────────────────────────────────────────
  List<String> _originalBookIds = [];

  Future<void> _fetchCollectionBooks(int collectionId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/collections/$collectionId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final bookList = data['books'] as List? ?? [];
        _originalBookIds = bookList.map((b) => b['bookId'].toString()).toList();
        selectedBooks.assignAll(
          bookList.map((b) => CollectionBook(
            id: b['bookId'].toString(),
            title: b['title'] ?? '',
            author: (b['authors'] is List && (b['authors'] as List).isNotEmpty)
                ? (b['authors'] as List).join(', ')
                : '',
            coverUrl: (b['thumbnail'] != null &&
                b['thumbnail'].toString().startsWith('http'))
                ? b['thumbnail']
                : null,
          )).toList(),
        );
      }
    } catch (e) {
      print('❌ _fetchCollectionBooks error: $e');
    }
  }

  void addBook(CollectionBook book) {
    if (!selectedBooks.any((b) => b.id == book.id)) {
      selectedBooks.add(book);
    }
  }

  void removeBook(String bookId) =>
      selectedBooks.removeWhere((b) => b.id == bookId);

  // ── 확인 / 취소 ────────────────────────────────────────────────────────────
  bool get isFormValid => titleController.text.trim().isNotEmpty;

  void onConfirm() async {
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

    isLoading.value = true;

    try {
      if (isEditMode.value && editingCollectionId != null) {
        await _updateCollection();
      } else {
        await _createCollection();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createCollection() async {
    final body = jsonEncode({
      'title': titleController.text.trim(),
      'isPrivate': isPrivate.value,
      'description': descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      'tags': selectedTags.map((t) => t.toJson()).toList(),
      'bookIds': selectedBooks.map((b) => int.tryParse(b.id) ?? 0).toList(),
    });

    final res = await http.post(
      Uri.parse('$baseUrl/collections'),
      headers: _headers,
      body: body,
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      print('✅ 컬렉션 생성 완료: ${data['collectionId']}');
      Get.back(result: {
        'collectionId': data['collectionId'],
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'isPrivate': isPrivate.value,
        'tags': selectedTags.map((t) => t.label).toList(),
        'bookIds': selectedBooks.map((b) => b.id).toList(),
      });
    } else {
      print('❌ 컬렉션 생성 실패: ${res.statusCode} ${res.body}');
      Get.snackbar('오류', '컬렉션 생성에 실패했습니다.');
    }
  }

  Future<void> _updateCollection() async {
    final body = jsonEncode({
      'title': titleController.text.trim(),
      'isPrivate': isPrivate.value,
      'description': descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      'tags': selectedTags.map((t) => t.toJson()).toList(),
    });

    final res = await http.put(
      Uri.parse('$baseUrl/collections/$editingCollectionId'),
      headers: _headers,
      body: body,
    );

    if (res.statusCode == 200) {
      await _syncBookChanges();
      await _updateBookOrder();

      print('✅ 컬렉션 수정 완료');

      Get.back(result: {
        'collectionId': editingCollectionId,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'isPrivate': isPrivate.value,
        'tags': selectedTags.map((t) => t.label).toList(),
        'bookIds': selectedBooks.map((b) => b.id).toList(),
      });
    } else {
      print('❌ 컬렉션 수정 실패: ${res.statusCode} ${res.body}');
      Get.snackbar('오류', '컬렉션 수정에 실패했습니다.');
    }
  }

  Future<void> _syncBookChanges() async {
    final originalIds = _originalBookIds.toSet();
    final currentIds = selectedBooks.map((b) => b.id).toSet();

    final toAdd = currentIds.difference(originalIds);
    for (final id in toAdd) {
      await http.post(
        Uri.parse('$baseUrl/collections/$editingCollectionId/books'),
        headers: _headers,
        body: jsonEncode({'bookId': int.tryParse(id) ?? 0}),
      );
    }

    final toDelete = originalIds.difference(currentIds);
    for (final id in toDelete) {
      await http.delete(
        Uri.parse('$baseUrl/collections/$editingCollectionId/books/$id'),
        headers: _headers,
      );
    }
    _originalBookIds = selectedBooks.map((b) => b.id).toList();
  }

  Future<void> _updateBookOrder() async {
    try {
      final bookIds = selectedBooks
          .map((b) => int.tryParse(b.id) ?? 0)
          .toList();

      final body = jsonEncode({'bookIds': bookIds});

      await http.put(
        Uri.parse('$baseUrl/collections/$editingCollectionId/books/order'),
        headers: _headers,
        body: body,
      );
      print('✅ 도서 순서 변경 완료');
    } catch (e) {
      print('❌ _updateBookOrder error: $e');
    }
  }

  void onCancel() => Get.back();

  // ── 도서 검색 페이지 이동 ──────────────────────────────────────────────────
  void navigateToBookSearch() async {
    final result = await Get.toNamed(
      '/collection/book_edit',
      arguments: List<CollectionBook>.from(selectedBooks),
    );
    if (result != null && result is List<CollectionBook>) {
      selectedBooks.assignAll(result);
    }
  }
}