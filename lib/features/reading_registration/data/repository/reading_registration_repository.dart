import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/reading_library_model.dart';
import '../models/reading_registration_session_model.dart';
import '../models/reading_book_summary_model.dart';

class ReadingRegistrationRepository extends GetConnect {
  final box = GetStorage();

  @override
  void onInit() {
    httpClient.baseUrl = 'https://api.43-202-101-63.sslip.io';
  }

  Future<List<ReadingLibraryItem>> getLibraryReadingItems() async {
    String token = box.read('access_token') ?? '';

    if (token.isEmpty) {
      print("Token not found");
      return [];
    }

    final response = await get(
      '/library/',
      query: {
        'shelf': 'reading',
        'sort': 'latest',
        'limit': '50',
      },
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.status.hasError) {
      print("Error fetching library items: ${response.statusText}");
      return [];
    }

    if (response.body != null) {
      final data = ReadingLibraryResponse.fromJson(response.body);
      return data.items.reversed.toList();
    }
    return [];
  }

  Future<ReadingRegistrationSession> startSession(int bookId, int? startPage) async {
    String token = box.read('access_token') ?? '';

    final response = await post(
      '/reading/sessions',
      {
        "book_id": bookId,
        if (startPage != null) "start_page": startPage
      },
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.status.hasError) {
      print("세션 시작 실패: ${response.body}");
      throw Exception('Start session failed');
    }

    return ReadingRegistrationSession.fromJson(response.body);
  }

  Future<ReadingRegistrationSession> endSession(int sessionId, int endPage, int totalSeconds) async {
    String token = box.read('access_token') ?? '';

    final response = await post(
      '/reading/sessions/$sessionId/end',
      {
        "end_page": endPage,
        "total_seconds": totalSeconds
      },
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.status.hasError) {
      print("세션 종료 실패: ${response.body}");
      throw Exception('End session failed');
    }

    return ReadingRegistrationSession.fromJson(response.body);
  }

  Future<ReadingBookSummary?> getBookSummary(int bookId) async {
    String token = box.read('access_token') ?? '';

    final response = await get(
      '/reading/summary',
      query: {'book_id': bookId.toString()},
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.status.hasError) {
      print("요약 정보 조회 실패: ${response.statusText}");
      return null;
    }

    if (response.body != null) {
      return ReadingBookSummary.fromJson(response.body);
    }
    return null;
  }
  Future<List<ReadingRegistrationSession>> getReadingSessions(int bookId) async {
    String token = box.read('access_token') ?? '';

    // 💡 Swagger 명세 규격: GET /reading/sessions?book_id={bookId} 완벽 싱크 바인딩
    final response = await get(
      '/reading/sessions',
      query: {'book_id': bookId.toString()},
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.status.hasError) {
      print("🚨 리포지토리 세션 목록 조회 실패: ${response.statusText}");
      return [];
    }

    if (response.body != null) {
      // 바디가 정상 List 형태로 들어오면 map 엔진 가동하여 오브젝트화
      final List<dynamic> rawList = response.body is List ? response.body : [];
      return rawList.map((e) => ReadingRegistrationSession.fromJson(e)).toList();
    }
    return [];
  }
}