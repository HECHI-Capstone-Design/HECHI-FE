import 'package:get/get.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class GenreBestsellerController extends GetxController {
  final RxList<Map<String, dynamic>> genreSections = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  String get _token => GetStorage().read('access_token') ?? "";

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $_token",
  };

  @override
  void onInit() {
    super.onInit();
    _fetchData();
  }

  Future<void> _fetchData() async {
    isLoading.value = true;
    try {
      // 1. 내 정보 조회하여 user_id 획득
      int? userId = await _fetchMyUserId();
      if (userId == null) {
        print("🚨 [장르] 유저 ID 없음");
        return;
      }

      // 2. 장르별 베스트셀러 조회
      final String apiUrl = '${AppConfig.baseUrl}/recommend/genre-bestseller?user_id=$userId&limit=10';

      final response = await http.get(Uri.parse(apiUrl), headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> curations = data['curations'];

        genreSections.value = curations.map((section) {
          String title = section['title'] ?? '추천 장르';
          List<dynamic> items = section['items'] ?? [];

          List<Map<String, dynamic>> books = items.map((item) => _parseBookItem(item)).toList().cast<Map<String, dynamic>>();

          return {
            'title': title,
            'books': books,
          };
        }).toList();
      } else {
        print('Genre API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Genre Network Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<int?> _fetchMyUserId() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/me'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['id'];
      }
    } catch (e) { /* 무시 */ }
    return null;
  }

  Map<String, dynamic> _parseBookItem(dynamic item) {
    List<dynamic>? authorsList = item['authors'];
    String authorName = (authorsList != null && authorsList.isNotEmpty) ? authorsList.join(', ') : '저자 미상';
    String imageUrl = item['thumbnail'] ?? 'https://via.placeholder.com/118x177.png?text=No+Image';

    var rawRating = item['average_rating'];
    String rating = '0.00';
    if (rawRating != null) {
      if (rawRating is num) rating = rawRating.toDouble().toStringAsFixed(2);
      else if (rawRating is String) {
        double? parsed = double.tryParse(rawRating);
        if (parsed != null) rating = parsed.toStringAsFixed(2);
      }
    }

    return {
      'id': item['id'],
      'title': item['title'] ?? '제목 없음',
      'rating': rating,
      'author': authorName,
      'imageUrl': imageUrl,
    };
  }
}