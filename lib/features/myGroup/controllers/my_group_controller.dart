// lib/features/myGroup/controllers/my_group_controller.dart

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // 💡 토큰을 읽어오기 위한 패키지 추가
import '../models/group_model.dart';

class MyGroupController extends GetxController {
  final GetConnect _connect = GetConnect();
  final GetStorage _storage = GetStorage(); // 💡 스토리지 인스턴스 생성

  var myGroups = <GroupModel>[].obs;
  var recommendedGroupsMain = <GroupModel>[].obs;
  var recommendedGroupsDetail = <GroupModel>[].obs;
  
  // 💡 실시간 서버 연동을 위해 초기값 true로 변경
  var isLoading = false.obs;

  static const String baseUrl = 'https://api.43-202-101-63.sslip.io';

  @override
  void onInit() {
    super.onInit();
    // 💡 화면이 켜지자마자 실전 API들을 동시다발적으로 트리거합니다.
    fetchMyGroups();
    fetchRecommendedGroups();
  }

  /// 🌐 1. [실전 API] 내 그룹 목록 가져오기 (GET /users/me/groups)
  Future<void> fetchMyGroups({bool isRetry = false}) async {
    try {
      if (!isRetry) isLoading.value = true;

      // 로컬 스토리지에서 access_token 추출
      final String? token = _storage.read('access_token');
      final headers = {
        'accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await _connect.get('$baseUrl/users/me/groups', headers: headers);

      // 💡 [403 에러 방어] 혹시 토큰이 만료되었다면 1회에 한해 자동으로 재발급 후 재시도합니다.
      if (response.statusCode == 403 && !isRetry) {
        bool isRefreshed = await _refreshAccessToken();
        if (isRefreshed) return await fetchMyGroups(isRetry: true);
        return;
      }

      if (response.status.isOk && response.body != null) {
        final List<dynamic> groupList = response.body['groups'] ?? [];
        
        // Swagger 응답 스펙(groupId, name)을 우리 GroupModel에 매핑
        myGroups.assignAll(
          groupList.map((json) => _mapJsonToGroupModel(json)).toList(),
        );
        print('✅ 내 그룹 API 연동 성공: 총 ${myGroups.length}개 로드됨');
      } else {
        print('❌ 내 그룹 API 에러: ${response.statusText} (${response.statusCode})');
        _loadMyGroupsDummy(); // 서버가 일시적으로 실패할 경우 최후의 방어선으로만 더미 작동
      }
    } catch (e) {
      print('❌ 내 그룹 통신 중 예외 발생: $e');
      _loadMyGroupsDummy();
    } finally {
      if (!isRetry) isLoading.value = false;
    }
  }

  /// 🌐 2. [실전 API] 추천 그룹 목록 가져오기 (GET /groups/recommendations)
  Future<void> fetchRecommendedGroups({bool isRetry = false}) async {
    try {
      if (!isRetry) isLoading.value = true;

      final String? token = _storage.read('access_token');
      final headers = {
        'accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // 메인 스크린용(10개)과 상세 리스트용(20개) API 호출
      final mainResponse = await _connect.get('$baseUrl/groups/recommendations?limit=10', headers: headers);
      final detailResponse = await _connect.get('$baseUrl/groups/recommendations?limit=20', headers: headers);

      if ((mainResponse.statusCode == 403 || detailResponse.statusCode == 403) && !isRetry) {
        bool isRefreshed = await _refreshAccessToken();
        if (isRefreshed) return await fetchRecommendedGroups(isRetry: true);
        return;
      }

      if (mainResponse.status.isOk && mainResponse.body != null) {
        final List<dynamic> groupList = mainResponse.body['groups'] ?? [];
        recommendedGroupsMain.assignAll(groupList.map((json) => _mapJsonToGroupModel(json)).toList());
      }

      if (detailResponse.status.isOk && detailResponse.body != null) {
        final List<dynamic> groupList = detailResponse.body['groups'] ?? [];
        recommendedGroupsDetail.assignAll(groupList.map((json) => _mapJsonToGroupModel(json)).toList());
      }
      print('✅ 추천 그룹 API 연동 성공 (Main: ${recommendedGroupsMain.length}개 / Detail: ${recommendedGroupsDetail.length}개)');
    } catch (e) {
      print('❌ 추천 그룹 API 통신 오류: $e');
    } finally {
      if (!isRetry) isLoading.value = false;
    }
  }

  /// 🔄 3. [보안 관리] 리프레시 토큰을 이용한 액세스 토큰 자동 재발급
  Future<bool> _refreshAccessToken() async {
    try {
      final String? refreshToken = _storage.read('refresh_token');
      if (refreshToken == null) return false;

      final response = await _connect.post(
        '$baseUrl/auth/refresh',
        {'refresh_token': refreshToken},
        headers: {'accept': 'application/json', 'Content-Type': 'application/json'},
      );

      if (response.status.isOk && response.body != null) {
        await _storage.write('access_token', response.body['access_token']);
        await _storage.write('refresh_token', response.body['refresh_token']);
        print('🔄 [성공] 토큰 만료 처리 완료 - 새 토큰으로 자동 갱신됨');
        return true;
      }
    } catch (e) {
      print('❌ 토큰 갱신 중 치명적 오류: $e');
    }
    return false;
  }

  /// 🧩 4. [데이터 매핑] JSON 구조 -> GroupModel 변환 공통 함수
  GroupModel _mapJsonToGroupModel(Map<String, dynamic> json) {
    return GroupModel(
      id: json['groupId']?.toString() ?? '',
      title: json['name'] ?? '이름 없는 그룹',
      // 리스트 뷰 아이템 카드 레이아웃의 서브 텍스트로 인원수가 이쁘게 표현되도록 포맷팅 처리
      description: json['description'] ?? '설명이 없는 그룹입니다.',
      authorName: json['maxMembers'] != null 
          ? '${json['memberCount']}/${json['maxMembers']}' 
          : 'dh', // 기본 방장 이름 분기
    );
  }

  /// 🛡️ 5. [네트워크 안전장치] API가 완전히 다운되었을 때 화면이 깨지는 걸 막아주는 낙하산 더미
  void _loadMyGroupsDummy() {
    if (myGroups.isEmpty) {
      myGroups.assignAll([
        GroupModel(id: '1', title: 'HECHI (서버오류 더미)', authorName: '1/10'),
        GroupModel(id: '2', title: 'BOOK CLUB (서버오류 더미)', authorName: '5/20'),
      ]);
    }
  }
}