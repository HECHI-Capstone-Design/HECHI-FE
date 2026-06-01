// lib/features/myGroup/controllers/my_group_controller.dart

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; 
import '../models/group_model.dart';

class MyGroupController extends GetxController {
  final GetConnect _connect = GetConnect();
  final GetStorage _storage = GetStorage(); 

  var myGroups = <GroupModel>[].obs;
  var recommendedGroupsMain = <GroupModel>[].obs;
  var recommendedGroupsDetail = <GroupModel>[].obs;

  var isLoading = false.obs;

  static const String baseUrl = 'https://api.43-202-101-63.sslip.io';

  @override
  void onInit() {
    super.onInit();
    fetchMyGroups();
    fetchRecommendedGroups();
  }

  /// 🌐 1. [실전 API] 내 그룹 목록 가져오기 (GET /users/me/groups)
  Future<void> fetchMyGroups({bool isRetry = false}) async {
    try {
      if (!isRetry) isLoading.value = true;

      final String? token = _storage.read('access_token');
      final headers = {
        'accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await _connect.get('$baseUrl/users/me/groups', headers: headers);

      if (response.statusCode == 403 && !isRetry) {
        bool isRefreshed = await _refreshAccessToken();
        if (isRefreshed) return await fetchMyGroups(isRetry: true);
        return;
      }

      if (response.status.isOk && response.body != null) {
        final List<dynamic> groupList = response.body['groups'] ?? [];

        myGroups.assignAll(
          groupList.map((json) => _mapJsonToGroupModel(json)).toList(),
        );
        print('✅ 내 그룹 API 연동 성공: 총 ${myGroups.length}개 로드됨');
      } else {
        print('❌ 내 그룹 API 에러: ${response.statusText} (${response.statusCode})');
        _loadMyGroupsDummy(); 
      }
    } catch (e) {
      print('❌ 내 그룹 통신 중 예외 발생: $e');
      _loadMyGroupsDummy();
    } finally {
      if (!isRetry) isLoading.value = false;
    }
  }

  /// 🌐 2. [실전 API] 추천 그룹 소거 필터링 + 방장 닉네임 상세 API 병렬 결합 통합본
  Future<void> fetchRecommendedGroups({bool isRetry = false}) async {
    try {
      if (!isRetry) isLoading.value = true;

      final String? token = _storage.read('access_token');
      final headers = {
        'accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final mainResponse = await _connect.get('$baseUrl/groups/recommendations?limit=10', headers: headers);
      final detailResponse = await _connect.get('$baseUrl/groups/recommendations?limit=20', headers: headers);

      if ((mainResponse.statusCode == 403 || detailResponse.statusCode == 403) && !isRetry) {
        bool isRefreshed = await _refreshAccessToken();
        if (isRefreshed) return await fetchRecommendedGroups(isRetry: true);
        return;
      }

      final Set<String> joinedGroupIds = myGroups.map((g) => g.id.toString()).toSet();

      if (mainResponse.status.isOk && mainResponse.body != null) {
        final List<dynamic> groupList = mainResponse.body['groups'] ?? [];

        final List<GroupModel> filteredMain = groupList
            .map((json) => _mapJsonToGroupModel(json))
            .where((group) => !joinedGroupIds.contains(group.id.toString()))
            .toList();

        await Future.wait(filteredMain.map((group) async {
          try {
            final detailRes = await _connect.get('$baseUrl/groups/${group.id}', headers: headers);
            if (detailRes.statusCode == 200 && detailRes.body != null) {
              final String realLeaderName = detailRes.body['leaderName'] ?? detailRes.body['leaderNickname'] ?? "방장 미상";
              group.leaderName = realLeaderName; 
            }
          } catch (_) {
            group.leaderName = "방장 미상"; 
          }
        }));

        recommendedGroupsMain.assignAll(filteredMain);
      }

      if (detailResponse.status.isOk && detailResponse.body != null) {
        final List<dynamic> groupList = detailResponse.body['groups'] ?? [];

        final List<GroupModel> filteredDetail = groupList
            .map((json) => _mapJsonToGroupModel(json))
            .where((group) => !joinedGroupIds.contains(group.id.toString()))
            .toList();

        await Future.wait(filteredDetail.map((group) async {
          try {
            final detailRes = await _connect.get('$baseUrl/groups/${group.id}', headers: headers);
            if (detailRes.statusCode == 200 && detailRes.body != null) {
              final String realLeaderName = detailRes.body['leaderName'] ?? detailRes.body['leaderNickname'] ?? "방장 미상";
              group.leaderName = realLeaderName;
            }
          } catch (_) {
            group.leaderName = "방장 미상";
          }
        }));

        recommendedGroupsDetail.assignAll(filteredDetail);
      }

      print('✅ 추천 필터링 및 방장 닉네임 병렬 바인딩 완수!');
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
    // 🚨 [동기화 정상화 핵심]: Swagger 정품 규격 'groupId' 필드를 확실히 획득하여 바인딩
    return GroupModel(
      id: json['groupId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['name'] ?? '이름 없는 그룹',
      description: json['description'] ?? '설명이 없는 그룹입니다.',
      authorName: '',
    );
  }

  /// 🛡️ 5. [네트워크 안전장치] 낙하산 더미 데이터
  void _loadMyGroupsDummy() {
    if (myGroups.isEmpty) {
      myGroups.assignAll([
        GroupModel(id: '1', title: 'HECHI (서버오류 더미)', authorName: '1/10'),
        GroupModel(id: '2', title: 'BOOK CLUB (서버오류 더미)', authorName: '5/20'),
      ]);
    }
  }
}