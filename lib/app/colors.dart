import 'package:flutter/material.dart';

/// HECHI 앱 공통 색상 정의
/// 모든 색상은 이 클래스에서만 참조한다.
abstract class AppColors {
  // ── Brand Green ──────────────────────────────────────
  /// 주 브랜드 색상 (버튼, 아이콘, 강조)
  static const Color primary = Color(0xFF4DB56C);

  /// 브랜드 연한 초록 (태그, 칩 배경)
  static const Color primarySurface = Color(0x7FD1ECD9);

  /// 브랜드 연한 초록 불투명 (뱃지, 아이콘 배경)
  static const Color primaryLight = Color(0xFF8DC695);

  // ── Text ─────────────────────────────────────────────
  /// 본문 / 강한 텍스트
  static const Color textDark = Color(0xFF3F3F3F);

  /// 보조 텍스트
  static const Color textMedium = Color(0xFF717171);

  /// 힌트 / 비활성 텍스트
  static const Color textHint = Color(0xFFABABAB);

  // ── Surface / Background ─────────────────────────────
  /// 순수 흰 배경
  static const Color white = Colors.white;

  /// 연한 회색 배경 (페이지 배경, 카드)
  static const Color backgroundGrey = Color(0xFFF5F5F5);

  // ── Border / Divider ─────────────────────────────────
  /// 구분선 (매우 연한)
  static const Color divider = Color(0xFFF3F3F3);

  /// 테두리 / 비활성 구분선
  static const Color border = Color(0xFFDADADA);

  /// 중간 테두리
  static const Color borderMedium = Color(0xFFD4D4D4);

  // ── Note Item Backgrounds ────────────────────────────
  /// 하이라이트 아이템 배경 (연한 노랑)
  static const Color highlightBackground = Color(0xFFFFF9C4);

  /// 메모 아이템 배경 (연한 핑크)
  static const Color memoBackground = Color(0xFFFFEBEE);

  // ── Status ───────────────────────────────────────────
  /// 에러 / 삭제
  static const Color error = Color(0xFFEA1717);

  /// 별점 / 골드
  static const Color star = Color(0xFFFFD700);
}
