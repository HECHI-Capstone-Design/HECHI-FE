import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 단일 아바타 렌더러.
///
/// 우선순위:
///   1. [imageUrl]이 null이 아니고 비어 있지 않으면 → NetworkImage 렌더
///   2. 그 외 → 회색 배경 + 흰색 person 아이콘 (회색 게스트 아이콘)
///
/// 초록색 아이콘은 이 함수에서 절대 사용하지 않습니다.
Widget buildUserAvatar(String? imageUrl, double radius) {
  final url = imageUrl?.trim() ?? '';
  if (url.isNotEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
    );
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: Colors.grey.shade300,
    child: Icon(Icons.person, color: Colors.white, size: radius * 1.2),
  );
}
