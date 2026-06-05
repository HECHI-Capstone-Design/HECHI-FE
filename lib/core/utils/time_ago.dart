/// ISO 8601 문자열을 한국 표준시(KST) 기준 상대 시간으로 변환
/// 예: "방금 전", "3분 전", "2시간 전", "5일 전"
String timeAgo(String? raw) {
  if (raw == null || raw.isEmpty) return '';

  DateTime? parsed;
  try {
    parsed = DateTime.parse(raw);
  } catch (_) {
    return raw;
  }

  // UTC → KST (+9)
  final kst = parsed.toUtc().add(const Duration(hours: 9));
  final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
  final diff = nowKst.difference(kst);

  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}개월 전';
  return '${(diff.inDays / 365).floor()}년 전';
}
