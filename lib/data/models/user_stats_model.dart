class UserStatsResponse {
  final List<RatingDist> ratingDistribution;
  final RatingSummary ratingSummary;
  final ReadingTime readingTime;
  final List<GenreStat> topLevelGenres;
  final List<GenreStat> subGenres;

  UserStatsResponse({
    required this.ratingDistribution,
    required this.ratingSummary,
    required this.readingTime,
    required this.topLevelGenres,
    required this.subGenres,
  });

  factory UserStatsResponse.fromJson(Map<String, dynamic> json) {
    return UserStatsResponse(
      ratingDistribution: ((json['ratingDistribution'] ?? json['rating_distribution']) as List? ?? [])
          .map((e) => RatingDist.fromJson(e)).toList(),
      ratingSummary: RatingSummary.fromJson(json['ratingSummary'] ?? json['rating_summary'] ?? {}),
      readingTime: ReadingTime.fromJson(json['readingTime'] ?? json['reading_time'] ?? {}),

      // ✅ [핵심 수정] 백엔드가 새로 바꾼 이름인 'genres'를 먼저 찾도록 추가했습니다!
      topLevelGenres: ((json['genres'] ?? json['topLevelGenres'] ?? json['top_level_genres']) as List? ?? [])
          .map((e) => GenreStat.fromJson(e)).toList(),

      subGenres: ((json['subGenres'] ?? json['sub_genres']) as List? ?? [])
          .map((e) => GenreStat.fromJson(e)).toList(),
    );
  }
}

class RatingDist {
  final double rating;
  final int count;

  RatingDist({required this.rating, required this.count});

  factory RatingDist.fromJson(Map<String, dynamic> json) {
    return RatingDist(
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class RatingSummary {
  final double average5;
  final int totalReviews;
  final double mostFrequentRating;
  final int average100;
  final int totalComments;

  RatingSummary({
    required this.average5,
    required this.totalReviews,
    required this.mostFrequentRating,
    required this.average100,
    required this.totalComments,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      // ✅ camelCase와 snake_case 모두 대응
      average5: ((json['average5'] ?? json['average_5']) as num?)?.toDouble() ?? 0.0,
      totalReviews: ((json['totalReviews'] ?? json['total_reviews']) as num?)?.toInt() ?? 0,
      mostFrequentRating: ((json['mostFrequentRating'] ?? json['most_frequent_rating']) as num?)?.toDouble() ?? 0.0,
      average100: ((json['average100'] ?? json['average_100']) as num?)?.toInt() ?? 0,
      totalComments: ((json['totalComments'] ?? json['total_comments']) as num?)?.toInt() ?? 0,
    );
  }
}

class ReadingTime {
  final int totalSeconds;
  final String human;

  ReadingTime({required this.totalSeconds, required this.human});

  factory ReadingTime.fromJson(Map<String, dynamic> json) {
    return ReadingTime(
      // ✅ camelCase와 snake_case 모두 대응
      totalSeconds: ((json['totalSeconds'] ?? json['total_seconds']) as num?)?.toInt() ?? 0,
      human: json['human'] ?? "0시간",
    );
  }
}

class GenreStat {
  final String name;
  final int reviewCount;
  final double average5;

  GenreStat({
    required this.name,
    required this.reviewCount,
    required this.average5,
  });

  factory GenreStat.fromJson(Map<String, dynamic> json) {
    return GenreStat(
      name: json['name'] ?? '',
      // ✅ camelCase와 snake_case 모두 대응
      reviewCount: ((json['reviewCount'] ?? json['review_count']) as num?)?.toInt() ?? 0,
      average5: ((json['average5'] ?? json['average_5']) as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserInsightResponse {
  final String analysis;
  final List<InsightTag> tags;

  UserInsightResponse({required this.analysis, required this.tags});

  factory UserInsightResponse.fromJson(Map<String, dynamic> json) {
    return UserInsightResponse(
      analysis: json['analysis'] ?? '',
      tags: (json['tags'] as List? ?? [])
          .map((e) => InsightTag.fromJson(e))
          .toList(),
    );
  }
}

class InsightTag {
  final String label;
  final double weight;

  InsightTag({required this.label, required this.weight});

  factory InsightTag.fromJson(Map<String, dynamic> json) {
    return InsightTag(
      label: json['label'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}