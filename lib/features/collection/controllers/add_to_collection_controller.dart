import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/collection_list_model.dart';
import '../models/collection_book_model.dart';
import '../../book_detail_page/controllers/book_detail_controller.dart';

class AddToCollectionController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  late final int bookId;

  final RxList<CollectionListItem> collections = <CollectionListItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<String> selectedCollectionIds = <String>{}.obs;

  String? get _token => box.read('access_token');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    bookId = (args != null && args is int) ? args : -1;
    loadMyCollections();
  }

  Future<void> loadMyCollections() async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$baseUrl/users/me/collections')
          .replace(queryParameters: {'bookId': bookId.toString()});
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        collections.assignAll(list);

        selectedCollectionIds.assignAll(
          list.where((c) => c.hasBook).map((c) => c.id).toSet(),
        );
      } else {
        print('❌ loadMyCollections 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ loadMyCollections error: $e');
    } finally {
      isLoading.value = false;
    }
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

  void navigateToCreateCollection() async {
    final bookDetailController = Get.find<BookDetailController>();
    final book = bookDetailController.book;

    final collectionBook = CollectionBook(
      id: bookId.toString(),
      title: book['title'] ?? '',
      author: (book['authors'] is List && (book['authors'] as List).isNotEmpty)
          ? (book['authors'] as List).join(', ')
          : '',
      coverUrl: book['thumbnail'],
    );

    final result = await Get.toNamed('/create_collection', arguments: collectionBook);

    if (result != null) {
      await loadMyCollections();
    }
  }

  void onConfirm() async {
    try {
      final originalIds = collections.where((c) => c.hasBook).map((c) => c.id).toSet();
      final toRemove = originalIds.difference(selectedCollectionIds);
      for (final id in toRemove) {
        await http.delete(
          Uri.parse('$baseUrl/collections/$id/books/$bookId'),
          headers: _headers,
        );
      }

      final toAdd = selectedCollectionIds.difference(originalIds);
      if (toAdd.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/collections/batch-add-book'),
          headers: _headers,
          body: jsonEncode({
            'bookId': bookId,
            'collectionIds': toAdd.map((id) => int.tryParse(id) ?? 0).toList(),
          }),
        );
      }

      print('✅ 컬렉션 도서 추가/삭제 완료');
      Get.back(result: selectedCollectionIds.toList());
    } catch (e) {
      print('❌ onConfirm error: $e');
      Get.snackbar('오류', '처리 중 오류가 발생했습니다.');
    }
  }

  void onCancel() => Get.back();
}