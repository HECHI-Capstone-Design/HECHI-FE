import 'dart:convert';
import 'package:hechi/app/config/app_config.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/collection_list_model.dart';
import '../../book_detail_page/controllers/book_detail_controller.dart';

class BookCollectionListController extends GetxController {
  final String baseUrl = AppConfig.baseUrl;
  final box = GetStorage();

  final RxList<CollectionListItem> collections = <CollectionListItem>[].obs;
  final RxBool isLoading = false.obs;

  late int bookId;

  String? get _token => box.read('access_token');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  void onInit() {
    super.onInit();
    bookId = Get.arguments ?? -1;
    loadCollections();
  }

  Future<void> loadCollections() async {
    isLoading.value = true;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/$bookId/collections'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        collections.assignAll(list);
        try {
          Get.find<BookDetailController>().collectionRefreshTrigger.value++;
        } catch (e) {}
      } else {
        print('❌ loadCollections 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ loadCollections error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleLike(String collectionId) async {
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index == -1) return;

    final item = collections[index];
    final isCurrentlyLiked = item.isLiked;

    collections[index] = item.copyWith(isLiked: !isCurrentlyLiked);

    try {
      final res = isCurrentlyLiked
          ? await http.delete(
        Uri.parse('$baseUrl/collections/$collectionId/like'),
        headers: _headers,
      )
          : await http.post(
        Uri.parse('$baseUrl/collections/$collectionId/like'),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        collections[index] = CollectionListItem(
          id: collections[index].id,
          title: collections[index].title,
          description: collections[index].description,
          authorName: collections[index].authorName,
          authorProfileUrl: collections[index].authorProfileUrl,
          tags: collections[index].tags,
          bookCoverUrls: collections[index].bookCoverUrls,
          likeCount: data['likeCount'],
          bookCount: collections[index].bookCount,
          isLiked: data['isLiked'],
          isPublic: collections[index].isPublic,
        );
      } else {
        collections[index] = item;
        print('❌ toggleLike 실패: ${res.statusCode}');
      }
    } catch (e) {
      collections[index] = item;
      print('❌ toggleLike error: $e');
    }
  }
}