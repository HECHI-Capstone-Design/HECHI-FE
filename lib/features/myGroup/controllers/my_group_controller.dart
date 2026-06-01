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

        // Swagger 응답 스펙(groupId, name)을 우리 GroupModel에 매핑
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

      // 🌐 1단계: 메인 스크린용(10개)과 상세 리스트용(20개) 추천 API 기본 호출
      final mainResponse = await _connect.get('$baseUrl/groups/recommendations?limit=10', headers: headers);
      final detailResponse = await _connect.get('$baseUrl/groups/recommendations?limit=20', headers: headers);

      // 🔑 토큰 만료 예외 대응 파이프라인
      if ((mainResponse.statusCode == 403 || detailResponse.statusCode == 403) && !isRetry) {
        bool isRefreshed = await _refreshAccessToken();
        if (isRefreshed) return await fetchRecommendedGroups(isRetry: true);
        return;
      }

      // 🛑 2단계: 내가 이미 가입 완료한 그룹들의 고유 ID 풀셋 확보 (소거 필터용)
      final Set<String> joinedGroupIds = myGroups.map((g) => g.id.toString()).toSet();

      // 🎯 3단계: 메인 스크린용 (limit=10) 가입 소거 및 방장 데이터 수집
      if (mainResponse.status.isOk && mainResponse.body != null) {
        final List<dynamic> groupList = mainResponse.body['groups'] ?? [];

        // 1) 가입 완료된 방 먼저 1차 스크리닝 거르기
        final List<GroupModel> filteredMain = groupList
            .map((json) => _mapJsonToGroupModel(json))
            .where((group) => !joinedGroupIds.contains(group.id.toString()))
            .toList();

        // 🔥 [핵심 이식]: 걸러진 추천 방들을 기반으로 각각 상세 API를 백그라운드에서 병렬 팩으로 호출
        await Future.wait(filteredMain.map((group) async {
          try {
            final detailRes = await _connect.get('$baseUrl/groups/${group.id}', headers: headers);
            if (detailRes.statusCode == 200 && detailRes.body != null) {
              // 상세 API 응답 바디에서 실제 정품 방장 닉네임 필드를 낚아챕니다.
              final String realLeaderName = detailRes.body['leaderName'] ?? detailRes.body['leaderNickname'] ?? "방장 미상";
              group.leaderName = realLeaderName; // 모델 객체에 동적 세팅
            }
          } catch (_) {
            group.leaderName = "방장 미상"; // 에러 발생 시 세이프 가드 플레이스홀더 세우기
          }
        }));

        recommendedGroupsMain.assignAll(filteredMain);
      }

      // 🎯 4단계: 상세 리스트용 (limit=20) 가입 소거 및 방장 데이터 수집
      if (detailResponse.status.isOk && detailResponse.body != null) {
        final List<dynamic> groupList = detailResponse.body['groups'] ?? [];

        // 1) 가입 완료된 방 1차 스크리닝 소거
        final List<GroupModel> filteredDetail = groupList
            .map((json) => _mapJsonToGroupModel(json))
            .where((group) => !joinedGroupIds.contains(group.id.toString()))
            .toList();

        // 🔥 마찬가지로 상세 API 병렬 동기화 팩 이식
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