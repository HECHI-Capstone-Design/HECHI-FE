import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CollectionDetailController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  late final int collectionId;

  final RxString collectionTitle = ''.obs;
  final RxString collectionDesc = ''.obs;
  final RxString creatorName = ''.obs;
  final RxList<String> tags = <String>[].obs;
  final RxList<String> thumbnailCovers = <String>[].obs;

  final RxInt likeCount = 0.obs;
  final RxBool isLiked = false.obs;
  final RxBool isMine = false.obs;
  final RxBool isPrivate = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isModified = false.obs;

  final RxList<Map<String, dynamic>> books = <Map<String, dynamic>>[].obs;

  String? get _token => box.read('access_token');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    collectionId = args is int ? args : int.tryParse(args.toString()) ?? -1;
    fetchDetail();
  }

  Future<void> fetchDetail({bool modified = false}) async {
    isLoading.value = true;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/collections/$collectionId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        collectionTitle.value = data['title'] ?? '';
        collectionDesc.value = data['description'] ?? '';
        creatorName.value = data['userName'] ?? '';
        likeCount.value = data['likeCount'] ?? 0;
        isLiked.value = data['isLiked'] ?? false;
        isMine.value = data['isMine'] ?? false;
        isPrivate.value = data['isPrivate'] ?? false;
        tags.assignAll(List<String>.from(data['tags'] ?? []));
        thumbnailCovers.assignAll(List<String>.from(data['thumbnailCovers'] ?? []));
        books.assignAll(List<Map<String, dynamic>>.from(data['books'] ?? []).toList(),);
        if(modified) isModified.value = true;
      } else {
        print('❌ fetchDetail 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ fetchDetail error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── 좋아요 토글
  void toggleLike() async {
    final wasLiked = isLiked.value;
    isLiked.value = !wasLiked;
    likeCount.value += wasLiked ? -1 : 1;

    try {
      final res = wasLiked
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
        isLiked.value = data['isLiked'];
        likeCount.value = data['likeCount'];
      } else {
        isLiked.value = wasLiked;
        likeCount.value += wasLiked ? 1 : -1;
      }
    } catch (e) {
      isLiked.value = wasLiked;
      likeCount.value += wasLiked ? 1 : -1;
      print('❌ toggleLike error: $e');
    }
  }

  // ── 컬렉션 삭제
  Future<void> deleteCollection() async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/collections/$collectionId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        print('✅ 컬렉션 삭제 완료');
        Get.back(result: {'deleted': true, 'collectionId': collectionId});
      } else {
        print('❌ 삭제 실패: ${res.statusCode}');
        Get.snackbar('오류', '컬렉션 삭제에 실패했습니다.');
      }
    } catch (e) {
      print('❌ deleteCollection error: $e');
    }
  }

  // ── 공유
  void shareCollection() {
    Get.snackbar('공유', '컬렉션 링크가 복사되었습니다.', snackPosition: SnackPosition.BOTTOM);
  }
}