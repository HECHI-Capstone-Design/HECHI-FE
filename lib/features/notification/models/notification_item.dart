import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// 공통 색상 상수 (앱 전체에서 사용)
// ─────────────────────────────────────────
const Color kNotifGreen      = Color(0xFF5C8C5A);
const Color kNotifGreenLight = Color(0xFFEAF3EA);
const Color kNotifBorder     = Color(0xFFD4D4D4);
const Color kNotifTextDark   = Color(0xFF3F3F3F);
const Color kNotifTextMid    = Color(0xFF5F5F5F);
const Color kNotifTextGrey   = Color(0xFF9E9E9E);

// ─────────────────────────────────────────
// 데이터 모델
// ─────────────────────────────────────────
enum NotificationType { general, group }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final String timeAgo;
  final String? imageUrl;  // 일반: 책 표지 / 그룹: 미션 책 표지
  final String? groupName; // 그룹 알림 전용
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timeAgo,
    this.imageUrl,
    this.groupName,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────
// 더미 데이터
// ─────────────────────────────────────────
final List<NotificationItem> generalNotificationDummies = [
  const NotificationItem(
    id: 'g1',
    type: NotificationType.general,
    title: '"기억을 잃었는데 지구를 구하라고요?"',
    description: '26년 상반기 영화 개봉! <마션> 앤디 위어의 경이로운 우주 활극 [프로젝트 헤일메리] 추천 소설',
    timeAgo: '2시간 전',
    imageUrl: 'https://picsum.photos/seed/book1/80/120',
  ),
  const NotificationItem(
    id: 'g2',
    type: NotificationType.general,
    title: '올해 최고의 스릴러, 압도적 몰입감!',
    description: '읽기 시작하면 멈출 수 없는 밀리언셀러 작가의 신작 스릴러 [침묵의 환자]를 지금 만나보세요.',
    timeAgo: '5시간 전',
    imageUrl: 'https://picsum.photos/seed/thriller/80/120',
  ),
  const NotificationItem(
    id: 'g3',
    type: NotificationType.general,
    title: '🎉 이달의 독서 배지 획득!',
    description: '축하합니다! 이번 달 목표 독서량 5권을 모두 달성하여 "열혈 독서가" 배지를 획득하셨습니다.',
    timeAgo: '1일 전',
    imageUrl: 'https://picsum.photos/seed/badge/80/120',
  ),
  const NotificationItem(
    id: 'g4',
    type: NotificationType.general,
    title: '따뜻한 위로가 필요한 당신에게 ☕',
    description: '50만 독자가 선택한 마음을 어루만지는 힐링 판타지 [비가 오면 열리는 상점] 신간 안내',
    timeAgo: '3일 전',
    imageUrl: 'https://picsum.photos/seed/healing/80/120',
  ),
  const NotificationItem(
    id: 'g5',
    type: NotificationType.general,
    title: '노르딕 누아르의 전설! 요 네스뵈 [블러드문]',
    description: '3년 만에 돌아온 <형사 해리 홀레> 시리즈 #13 모든 것을 잃고 산산이 부서졌던 해리의 귀환!',
    timeAgo: '1주 전',
    imageUrl: 'https://picsum.photos/seed/book5/80/120',
  ),
];

final List<NotificationItem> groupNotificationDummies = [
  const NotificationItem(
    id: 'gr1',
    type: NotificationType.group,
    title: '[HECHI 그룹]',
    description: '새로운 공지사항이 등록되었습니다.',
    timeAgo: '1시간 전',
    groupName: 'HECHI 그룹',
  ),
  const NotificationItem(
    id: 'gr2',
    type: NotificationType.group,
    title: '[HECHI 그룹]',
    description: 'Summer 님이 가입하셨습니다.',
    timeAgo: '3시간 전',
    groupName: 'HECHI 그룹',
  ),
  const NotificationItem(
    id: 'gr3',
    type: NotificationType.group,
    title: '[HECHI 그룹]',
    description: "그룹장님이 미션 책 '프로젝트 헤일메리'를 지정하였습니다.",
    timeAgo: '어제',
    imageUrl: 'https://picsum.photos/seed/grbook1/80/120',
    groupName: 'HECHI 그룹',
  ),
  const NotificationItem(
    id: 'gr4',
    type: NotificationType.group,
    title: '[HECHI 그룹]',
    description: "그룹장님이 미션 책 '혼모노'로 변경하였습니다.",
    timeAgo: '2일 전',
    imageUrl: 'https://picsum.photos/seed/grbook2/80/120',
    groupName: 'HECHI 그룹',
  ),
  const NotificationItem(
    id: 'gr5',
    type: NotificationType.group,
    title: '[HECHI 그룹]',
    description: 'Sonny 님이 그룹을 탈퇴하셨습니다.',
    timeAgo: '3일 전',
    groupName: 'HECHI 그룹',
  ),
];