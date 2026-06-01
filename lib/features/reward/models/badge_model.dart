class BadgeModel {
  final int badgeId;
  final String code;
  final String category;
  final String title;
  final String description;
  final DateTime? earnedAt;

  BadgeModel({
    required this.badgeId,
    required this.code,
    required this.category,
    required this.title,
    required this.description,
    this.earnedAt,
  });

  // earnedAt이 null이 아니면 획득한 상태(true)가 됩니다.
  bool get isEarned => earnedAt != null;
}