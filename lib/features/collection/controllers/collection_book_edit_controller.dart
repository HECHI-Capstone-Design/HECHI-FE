import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/collection_book_model.dart';

class CollectionBookEditController extends GetxController {
  final TextEditingController searchController = TextEditingController();

  final RxList<CollectionBook> books = <CollectionBook>[].obs;
  final RxList<CollectionBook> searchResults = <CollectionBook>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();

    // 이전 페이지에서 현재 담긴 도서 리스트를 arguments로 받아옴
    // TODO: Replace dummy data with API response
    final args = Get.arguments;
    if (args != null && args is List<CollectionBook>) {
      books.assignAll(args);
    } else {
      // 더미 초기 데이터
      books.assignAll([
        const CollectionBook(id: '1', title: '혼모노', author: '성해나'),
        const CollectionBook(id: '2', title: '괴테는 모든 것을 말했다', author: '스조키 유이'),
      ]);
    }

    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _onSearchChanged(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ── 검색 ───────────────────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;

    // TODO: Replace dummy data with API response
    // GET /books?q={query}
    final q = query.toLowerCase();
    searchResults.assignAll(
      dummySearchBooks
          .where((b) =>
      !books.any((existing) => existing.id == b.id) &&
          (b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q)))
          .toList(),
    );
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
    isSearching.value = false;
  }

  // ── 도서 추가 (검색 결과에서 선택) ────────────────────────────────────────
  void addBook(CollectionBook book) {
    if (!books.any((b) => b.id == book.id)) {
      books.insert(0, book); // 리스트 상단에 추가
    }
    clearSearch();
  }

  // ── 도서 삭제 ──────────────────────────────────────────────────────────────
  void removeBook(String bookId) {
    books.removeWhere((b) => b.id == bookId);
  }

  // ── 도서 순서 변경 (드래그) ────────────────────────────────────────────────
  void reorderBooks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = books.removeAt(oldIndex);
    books.insert(newIndex, item);
  }

  // ── 완료 → 이전 페이지로 결과 전달 ───────────────────────────────────────
  void onConfirm() {
    // TODO: Replace dummy data with API response
    // PATCH /collections/{id}/books 로 교체
    Get.back(result: List<CollectionBook>.from(books));
  }

  void onBack() {
    Get.back(result: List<CollectionBook>.from(books));
  }
}