import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 전역 환경설정.
///
/// 실제 값은 프로젝트 루트의 `.env` 파일에서 읽어옵니다.
/// `.env`가 누락되었거나 키가 없을 경우를 대비해 기본값을 둡니다.
class AppConfig {
  AppConfig._();

  /// API 서버 base URL. (`.env`의 BASE_URL)
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://api.43-202-101-63.sslip.io';
}
