import 'package:get/get.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarController extends GetxController {
  final box = GetStorage();

  // API 주소
  final String baseUrl = AppConfig.baseUrl;

  // 캘린더 상태 변수
  RxInt currentYear = DateTime.now().year.obs;
  RxInt currentMonth = DateTime.now().month.obs;

  // API 데이터 변수
  RxInt totalReadCount = 0.obs;
  RxString topGenre = "".obs;

  // 1. 달력 그리드에 보여줄 표지
  RxMap<int, String> calendarBooks = <int, String>{}.obs;

  // 2. 바텀 시트에 보여줄 상세 리스트
  RxMap<int, List<dynamic>> dailyBooks = <int, List<dynamic>>{}.obs;

  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCalendarData();
  }

  // 월 변경 함수
  void changeMonth(int offset) {
    DateTime newDate = DateTime(currentYear.value, currentMonth.value + offset);
    currentYear.value = newDate.year;
    currentMonth.value = newDate.month;
    fetchCalendarData();
  }

  // ✅ [수정됨] 정확한 영어 문구를 한글로 매핑 (Business & Economics 추가)
  String _convertGenreToKorean(String? genre) {
    if (genre == null || genre.isEmpty) return "-";

    // 소문자로 변환하여 비교 (API 대소문자 불일치 방지)
    final key = genre.toLowerCase().trim();

    const Map<String, String> genreMap = {
      // 🚨 문제가 되었던 부분 수정 (정확한 풀네임 추가)
      'business & economics': '경제/경영',
      'computers': 'IT/컴퓨터',
      'health & fitness': '건강/운동',
      'comics & graphic novels': '만화',
      'literary collections': '문학전집',
      'foreign language study': '외국어',
      'social science': '사회과학',
      'political science': '정치/사회',
      'performing arts': '대중예술',

      // 기존 단어 매핑
      'fiction': '소설',
      'novel': '소설',
      'poetry': '시',
      'essay': '에세이',
      'romance': '로맨스',
      'fantasy': '판타지',
      'mystery': '추리',
      'sf': 'SF',
      'thriller': '스릴러',
      'humanities': '인문학',
      'history': '역사',
      'science': '과학',
      'art': '예술',
      'social': '사회',
      'religion': '종교',
      'philosophy': '철학',
      'self-help': '자기계발',
      'self_development': '자기계발',
      'economy': '경제/경영',
      'management': '경제/경영',
      'marketing': '마케팅',
      'it': 'IT/컴퓨터',
      'computer': 'IT/컴퓨터',
      'cartoon': '만화',
      'comics': '만화',
      'magazine': '잡지',
      'reference': '참고서',
    };

    // 1. 정확히 일치하는 키가 있는지 확인
    if (genreMap.containsKey(key)) {
      return genreMap[key]!;
    }

    // 2. 정확히 일치하지 않으면 부분 검색 (예: "juvenile fiction" -> "소설")
    if (key.contains('fiction') || key.contains('novel')) return '소설';
    if (key.contains('history')) return '역사';
    if (key.contains('science')) return '과학';
    if (key.contains('art')) return '예술';
    if (key.contains('computer')) return 'IT/컴퓨터';
    if (key.contains('business') || key.contains('economic')) return '경제/경영';
    if (key.contains('comic')) return '만화';

    // 매핑 실패 시 원래 영어 텍스트 반환
    return genre;
  }

  // API 호출
  Future<void> fetchCalendarData() async {
    String? token = box.read('access_token');

    if (token == null) {
      print("🚨 [Calendar] 토큰 없음. 로그인이 필요합니다.");
      return;
    }

    isLoading.value = true;

    final queryParams = {
      'year': currentYear.value.toString(),
      'month': currentMonth.value.toString(),
    };

    final url = Uri.parse('$baseUrl/analytics/calendar-month').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        totalReadCount.value = data['total_read_count'] ?? 0;

        // ✅ 한글 변환 적용
        String rawGenre = data['top_genre'] ?? "";
        topGenre.value = _convertGenreToKorean(rawGenre);

        Map<int, String> newCovers = {};
        Map<int, List<dynamic>> newDaily = {};

        List days = data['days'] ?? [];

        for (var dayData in days) {
          try {
            String dateStr = dayData['date'];
            DateTime date = DateTime.parse(dateStr);
            List items = dayData['items'] ?? [];

            if (items.isNotEmpty) {
              String? thumbnail = items[0]['thumbnail'];
              if (thumbnail != null && thumbnail.isNotEmpty) {
                newCovers[date.day] = thumbnail;
              }
              newDaily[date.day] = items;
            }
          } catch (e) {
            print("⚠️ 날짜 데이터 파싱 중 에러: $e");
          }
        }

        calendarBooks.value = newCovers;
        dailyBooks.value = newDaily;

      } else {
        print("❌ 요청 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 네트워크 오류 발생: $e");
    } finally {
      isLoading.value = false;
    }
  }
}