import 'package:get/get.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class BestsellerController extends GetxController {
  final RxList<Map<String, dynamic>> bookList = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  String get _token => GetStorage().read('access_token') ?? "";
  Map<String, String> get _headers => {
    "Content-Type": "application/json", "Accept": "application/json", "Authorization": "Bearer $_token",
  };

  @override
  void onInit() {
    super.onInit();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    isLoading.value = true;
    final String apiUrl = '${AppConfig.baseUrl}/recommend/bestseller?limit=30';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: _headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = data['items'];
        bookList.value = items.map((item) => _parseBookItem(item)).toList().cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Bestseller Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 파싱 함수 (GenreBestsellerController와 동일)
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
    return {'id': item['id'], 'title': item['title'] ?? '제목 없음', 'rating': rating, 'author': authorName, 'imageUrl': imageUrl};
  }
}