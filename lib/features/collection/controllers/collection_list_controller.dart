import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/collection_list_model.dart';
import '../../my_read/controllers/my_read_controller.dart';

class CollectionListController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  final RxList<CollectionListItem> collections = <CollectionListItem>[].obs;
  final RxBool isLoading = false.obs;

  String? get _token => box.read('access_token');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  void onInit() {
    super.onInit();
    loadCollections();
  }

  Future<void> loadCollections() async {
    isLoading.value = true;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/me/collections'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        collections.assignAll(list);
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
        collections[index] = collections[index].copyWith(
          isLiked: data['isLiked'],
        );
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

  void navigateToCreateCollection() async {
    final result = await Get.toNamed('/create_collection');
    if (result != null && result is Map<String, dynamic>) {
      if (result['deleted'] == true) {
        collections.removeWhere((c) => c.id == result['collectionId'].toString());
      } else {
        await loadCollections();
        _updateMyReadCollectionCount();
      }
    }
  }

  void navigateToCollectionDetail(String collectionId) async {
    final result = await Get.toNamed('/collection_detail', arguments: collectionId);
    if (result != null && result is Map<String, dynamic>) {
      if (result['deleted'] == true) {
        collections.removeWhere((c) => c.id == result['collectionId'].toString());
        _updateMyReadCollectionCount();
      } else if (result['updated'] == true) {
        await loadCollections();
      }
    } else {
      await loadCollections();
    }
  }

  void _updateMyReadCollectionCount() {
    try {
      final myReadController = Get.find<MyReadController>();
      myReadController.totalCollections.value = collections.length.toString();
    } catch (e) {}
  }
}
