import 'dart:convert';
import 'package:hechi/app/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../models/badge_model.dart';

class RewardController extends GetxController {
  final List<Map<String, String>> badgeSchemaList = [
    {'code': 'beginner_5', 'category': 'reading', 'title': '독서 비기너', 'desc': '완독 책 5권 이상'},
    {'code': 'pro_10', 'category': 'reading', 'title': '독서 프로', 'desc': '완독 책 10권 이상'},
    {'code': 'master_20', 'category': 'reading', 'title': '독서 마스터', 'desc': '완독 책 20권 이상'},
    {'code': 'library_50', 'category': 'reading', 'title': '걸어 다니는 도서관', 'desc': '완독 책 50권 이상'},
    {'code': 'fairy_10', 'category': 'rating', 'title': '별점 요정', 'desc': '평점 10개 이상'},
    {'code': 'craft_30', 'category': 'rating', 'title': '별점 장인', 'desc': '평점 30개 이상'},
    {'code': 'restaurant_100', 'category': 'rating', 'title': '별점 맛집', 'desc': '평점 100개 이상'},
    {'code': 'poem_5', 'category': 'review', 'title': '리뷰로 시 쓰기', 'desc': '리뷰 5개 이상'},
    {'code': 'short_15', 'category': 'review', 'title': '리뷰로 단편 쓰기', 'desc': '리뷰 15개 이상'},
    {'code': 'author_30', 'category': 'review', 'title': '리뷰로 작가 등단!', 'desc': '리뷰 30개 이상'},
    {'code': 'lover_10', 'category': 'genre', 'title': '해당 장르 러버', 'desc': '특정 장르 평점 10개 이상'},
    {'code': 'omnireader_10genres', 'category': 'genre', 'title': '잡독(서)러', 'desc': '평점 남긴 장르 10개 이상'},
    {'code': 'desire_30', 'category': 'wishlist', 'title': '독서의 욕망은 끝이 없어!', 'desc': '위시리스트 30권 이상'},
    {'code': 'collector_10', 'category': 'bookmark', 'title': '문장 수집가', 'desc': '북마크 10개 이상'},
    {'code': 'lover_50', 'category': 'bookmark', 'title': '활자 애호가', 'desc': '북마크 50개 이상'},
  ];

  final rxBadges = <BadgeModel>[].obs;
  final RxBool isLoading = false.obs;
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchUserBadges();
  }

  Future<void> fetchUserBadges() async {
    isLoading.value = true;
    try {
      final String? token = box.read<String>('access_token');

      final url = Uri.parse('${AppConfig.baseUrl}/users/me/badges');
      final Map<String, String> headers = {
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      List<dynamic> apiBadges = [];

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedData != null && decodedData['badges'] != null) {
          apiBadges = decodedData['badges'] as List<dynamic>;
        }
      }

      List<BadgeModel> list = [];
      for (var schema in badgeSchemaList) {
        // 💡 [수정] 서버에서 준 code(예: 'reading.beginner_5')에 프론트엔드의 키값('beginner_5')이 포함되어 있는지 검사합니다.
        final earned = apiBadges.firstWhereOrNull((e) => 
          e != null && e['code'] != null && e['code'].toString().contains(schema['code']!)
        );
        
        final bool hasEarnedAt = earned != null && earned['earnedAt'] != null;

        list.add(BadgeModel(
          badgeId: earned != null ? (earned['badgeId'] ?? -1) : -1,
          code: schema['code'] ?? '',
          category: schema['category'] ?? '',
          title: schema['title'] ?? '',
          description: schema['desc'] ?? '',
          earnedAt: hasEarnedAt ? DateTime.tryParse(earned['earnedAt'].toString()) : null,
        ));
      }
      rxBadges.assignAll(list);
    } catch (e) {
      debugPrint('❌ 리워드 처리 중 예외 에러 발생: $e');
    } finally {
      isLoading.value = false;
    }
  }
}