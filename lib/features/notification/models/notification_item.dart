import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// 공통 색상 상수
// ─────────────────────────────────────────
const Color kNotifGreen      = Color(0xFF5C8C5A);
const Color kNotifGreenLight = Color(0xFFEAF3EA);
const Color kNotifBorder     = Color(0xFFD4D4D4);
const Color kNotifTextDark   = Color(0xFF3F3F3F);
const Color kNotifTextMid    = Color(0xFF5F5F5F);
const Color kNotifTextGrey   = Color(0xFF9E9E9E);

class NotificationItem {
  final int notificationId;
  final String tabCategory;
  final String type;
  final String title;
  final String message;
  final String? thumbnailUrl;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> targetInfo;

  const NotificationItem({
    required this.notificationId,
    required this.tabCategory,
    required this.type,
    required this.title,
    required this.message,
    this.thumbnailUrl,
    required this.isRead,
    required this.createdAt,
    required this.targetInfo,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // 🚀 타임존(9시간) 오차 해결을 위한 날짜 파싱 로직
    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      String dateStr = json['createdAt'].toString();
      // 백엔드에서 Z를 빼먹고 보냈을 경우 강제로 붙여서 UTC로 파싱 후 한국 시간으로 변환
      if (!dateStr.endsWith('Z')) {
        dateStr += 'Z';
      }
      parsedDate = DateTime.parse(dateStr).toLocal();
    }

    return NotificationItem(
      notificationId: json['notificationId'] is int
          ? json['notificationId']
          : int.parse(json['notificationId'].toString()),
      tabCategory: json['tabCategory'] ?? 'GENERAL',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      isRead: json['isRead'] ?? false,
      createdAt: parsedDate, // ✅ 수정된 파싱 날짜 적용
      targetInfo: json['targetInfo'] ?? {},
    );
  }

  // UI 호환용 Getter
  String get id => notificationId.toString();
  String get description => message;
  String? get imageUrl => thumbnailUrl;

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inMinutes < 60) return '${difference.inMinutes}분 전';
    if (difference.inHours < 24) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    return '${createdAt.year}.${createdAt.month}.${createdAt.day}';
  }
}g