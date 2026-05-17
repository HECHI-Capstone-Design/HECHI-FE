import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/collection_book_model.dart';


class CollectionBookEditController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  final TextEditingController searchController = TextEditingController();

  final RxList<CollectionBook> books = <CollectionBook>[].obs;
  final RxList<CollectionBook> searchResults = <CollectionBook>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool isSearchLoading = false.obs;

  Timer? _debounceTimer;

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
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        const Duration(milliseconds: 500),
          () => _onSearchChanged(searchController.text),
      );
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ── 검색 ───────────────────────────────────────────────────────────────────
  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    isSearching.value = true;
    isSearchLoading.value = true;

    try {
      final token = box.read('access_token');
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final res = await http.post(
        Uri.parse('$baseUrl/search/query'),
        headers: headers,
        body: jsonEncode({
          'query': query.trim(),
          'limit': 20,
          'save_history': false,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final List books_raw = data['books'] ?? [];

        final results = books_raw
          .map((b) => CollectionBook(
            id: b['id'].toString(),
            title: b['title'] ?? '',
            author: b['authors'] != null && (b['authors'] as List).isNotEmpty
                ? (b['authors'] as List).join(', ')
                : '작자 미상',
            coverUrl: (b['thumbnail'] != null &&
                b['thumbnail'].toString().startsWith('http'))
                ? b['thumbnail']
                : null,
          ))
          .where((b) => !books.any((existing) => existing.id == b.id))
          .toList();

        searchResults.assignAll(results);
      } else {
        print('❌ Search failed: ${res.statusCode}');
        searchResults.clear();
      }
    } catch (e) {
      print('❌ Search error: $e');
      searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
    isSearching.value = false;
  }

  // ── 도서 추가  ──────────────────────────────────────────────────────────────
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

  // ── 도서 순서 변경  ────────────────────────────────────────────────────────
  void reorderBooks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = books.removeAt(oldIndex);
    books.insert(newIndex, item);
  }

  // ── 완료  ─────────────────────────────────────────────────────────────────
  void onConfirm() {
    // TODO: Replace dummy data with API response
    // PATCH /collections/{id}/books 로 교체
    Get.back(result: List<CollectionBook>.from(books));
  }

  void onBack() {
    Get.back(result: List<CollectionBook>.from(books));
  }
}