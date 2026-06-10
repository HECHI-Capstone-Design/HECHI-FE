import 'package:get/get.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'dart:ui';
import '../../../data/models/user_stats_model.dart';
import '../../../app/controllers/app_controller.dart';

class TasteAnalysisController extends GetxController {
  final String baseUrl = AppConfig.baseUrl;
  final box = GetStorage();
  RxBool isLoading = true.obs;

  RxMap<String, dynamic> get userProfile => Get.find<AppController>().userProfile;

  RxList<Map<String, dynamic>> starRatingDistribution = <Map<String, dynamic>>[
    {'score': 5.0, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 4.5, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 4.0, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 3.5, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 3.0, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 2.5, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 2.0, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 1.5, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 1.0, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
    {'score': 0.5, 'ratio': 0.0, 'color': 0xFFAAD2B6, 'count': 0},
  ].obs;

  RxString averageRating = "0.0".obs;
  RxString totalReviews = "0.0".obs;
  RxString readingRate = "0%".obs;
  RxString mostGivenRating = "0.0".obs;
  RxString totalReadingTime = "0.0".obs;

  RxList<Map<String, dynamic>> tags = <Map<String, dynamic>>[].obs;
  RxList<GenreStat> genreRankings = <GenreStat>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    String? token = box.read('access_token');
    print("📢 [fetchData 실행됨] 토큰 유무: ${token != null}");

    if (token != null) {
      try {
        await Future.wait([
          _fetchMyStats(token),
          _fetchInsightTags(token),
        ]);
      } catch (e) {
        print("🚨 데이터 로딩 오류: $e");
      }
    }
    isLoading.value = false;
  }

  Future<void> _fetchMyStats(String token) async {
    final url = Uri.parse('$baseUrl/analytics/my-stats');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

    print("📢 [장르 API 응답 상태코드]: ${response.statusCode}");
    print("📢 [장르 API 실제 데이터]: ${utf8.decode(response.bodyBytes)}");

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final stats = UserStatsResponse.fromJson(json);

        averageRating.value = stats.ratingSummary.average5.toStringAsFixed(1);
        totalReviews.value = stats.ratingSummary.totalReviews.toString();
        readingRate.value = "${stats.ratingSummary.average100}%";
        mostGivenRating.value = stats.ratingSummary.mostFrequentRating.toStringAsFixed(1);

        String rawTime = stats.readingTime.human;
        String cleaned = rawTime
            .replaceAll("총", "")
            .replaceAll("감상하였습니다", "")
            .replaceAll("감상하셨습니다", "")
            .replaceAll("동안", "")
            .replaceAll(".", "")
            .trim();

        if (cleaned.contains("분") && !cleaned.contains("시간")) {
          String numStr = cleaned.replaceAll("분", "").trim();
          int? mins = int.tryParse(numStr);
          if (mins != null) {
            if (mins < 60) {
              totalReadingTime.value = "${mins}분";
            } else {
              int h = mins ~/ 60;
              int m = mins % 60;
              if (m == 0) {
                totalReadingTime.value = "${h}시간";
              } else {
                totalReadingTime.value = "${h}시간 ${m}분";
              }
            }
          } else {
            totalReadingTime.value = cleaned;
          }
        }
        else if (cleaned == "0시간") {
          totalReadingTime.value = "0분";
        }
        else {
          totalReadingTime.value = cleaned;
        }

        _updateDistribution(stats.ratingDistribution);

        List<GenreStat> sourceList = stats.subGenres.isNotEmpty
            ? stats.subGenres
            : stats.topLevelGenres;
        List<GenreStat> mergedList = [];
        int bizEcoCount = 0;
        double bizEcoTotalScore = 0.0;
        bool hasBizEco = false;

        for (var genre in sourceList) {
          if (genre.name.contains('경제') || genre.name.contains('경영')) {
            hasBizEco = true;
            bizEcoCount += genre.reviewCount;
            bizEcoTotalScore += (genre.average5 * genre.reviewCount);
          } else {
            mergedList.add(genre);
          }
        }

        if (hasBizEco && bizEcoCount > 0) {
          mergedList.add(GenreStat(
            name: '경제/경영',
            reviewCount: bizEcoCount,
            average5: bizEcoTotalScore / bizEcoCount,
          ));
        }

        genreRankings.value = mergedList;
        genreRankings.sort((a, b) => b.average5.compareTo(a.average5));

      } catch (e) {
        print("🚨 [장르 모델 파싱 에러 발생!!]: $e");
      }
    }
  }

  Future<void> _fetchInsightTags(String token) async {
    final url = Uri.parse('$baseUrl/analytics/my-insights');

    final List<Offset> presetPositions = [
      const Offset(0.50, 0.45), const Offset(0.40, 0.60), const Offset(0.60, 0.30),
      const Offset(0.75, 0.50), const Offset(0.25, 0.50), const Offset(0.30, 0.20),
      const Offset(0.70, 0.70), const Offset(0.50, 0.85), const Offset(0.20, 0.80),
    ];

    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      print("📢 [태그 API 응답 상태코드]: ${response.statusCode}");
      print("📢 [태그 API 실제 데이터]: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final insightData = UserInsightResponse.fromJson(json);

        if (insightData.tags.isEmpty) return;

        List<Map<String, dynamic>> newTags = [];
        var sortedTags = insightData.tags;
        sortedTags.sort((a, b) => b.weight.compareTo(a.weight));
        var topTags = sortedTags.take(9).toList();

        var highestTag = topTags.isNotEmpty ? topTags.removeAt(0) : null;
        var topThree = topTags.take(3).toList();
        var remainingTags = topTags.skip(3).toList();

        var finalTags = [
          ...topThree,
          ...remainingTags,
          if (highestTag != null) highestTag,
        ];

        const int topTagColor = 0xFF4EB56D;
        const int otherTagColor = 0xFFAAD2B6;
        const double topTagSize = 14.0;
        const double otherTagSize = 9.0;

        int tagIndex = 0;
        for (var tag in finalTags) {
          double size;
          int color;

          if (tagIndex < 3) {
            size = topTagSize;
            color = topTagColor;
          } else {
            size = otherTagSize;
            color = otherTagColor;
          }

          Offset position = presetPositions[tagIndex % presetPositions.length];

          newTags.add({
            'text': tag.label,
            'size': size,
            'color': color,
            'position': position,
          });
          tagIndex++;
        }
        tags.value = newTags;
      }
    } catch (e) {
      print("🚨 [태그 모델 파싱 에러 발생!!]: $e");
    }
  }

  void _updateDistribution(List<RatingDist> distData) {
    int maxCount = 0;

    for (var d in distData) {
      if (d.count > maxCount) maxCount = d.count;
    }

    const int darkGreenColor = 0xFF4EB56D;
    const int lightGreenColor = 0xFFAAD2B6;

    var newDist = <Map<String, dynamic>>[];
    const double minRatioForOneCount = 0.02;

    for (int i = 0; i < starRatingDistribution.length; i++) {
      var item = starRatingDistribution[i];
      double score = (item['score'] as num).toDouble();
      int count = 0;

      try {
        var apiData = distData.firstWhere(
              (d) => (d.rating.toDouble() - score).abs() < 0.001,
          orElse: () => RatingDist(rating: 0, count: 0),
        );
        count = apiData.count;
      } catch (e) {
        count = 0;
      }

      double ratio = 0.0;
      if (count == 0) {
        ratio = 0.0;
      } else {
        double calculatedRatio = maxCount > 0 ? (count / maxCount) : 0.0;
        ratio = calculatedRatio.isFinite && calculatedRatio > 0
            ? calculatedRatio.clamp(minRatioForOneCount, 1.0)
            : minRatioForOneCount;
      }

      int color = lightGreenColor;
      if (count == maxCount && maxCount > 0) {
        color = darkGreenColor;
      }

      newDist.add({'score': score, 'ratio': ratio, 'color': color, 'count': count});
    }
    starRatingDistribution.value = newDist;
  }
}