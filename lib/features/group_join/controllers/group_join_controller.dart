// lib/features/group_join/controllers/group_join_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../myGroup/models/group_model.dart'; 
import '../../myGroup/controllers/my_group_controller.dart'; 

class GroupJoinController extends GetxController {
  final GetConnect _connect = GetConnect();
  final String serverBaseUrl = 'https://api.43-202-101-63.sslip.io';

  // true: 공개 그룹, false: 비공개 그룹
  final isPublic = true.obs; 

  final groupName = ''.obs;
  final memberCount = '0/0'.obs; 
  final createdDate = ''.obs;
  final masterNickname = ''.obs;
  final description = ''.obs;

  // 💡 [실전 구조화] 서버에서 받아온 미션 도서 목록을 안전하게 담을 반응형 리스트
  final books = <Map<String, String>>[].obs;

  // 이미 가입한 그룹인지 실시간 추적하는 상태 변수
  var isAlreadyJoined = false.obs;
  // 넘겨받은 현재 그룹 모델 캐싱 변수
  GroupModel? currentGroup;

  final passwordController = TextEditingController();
  final isPageLoading = false.obs; // 상세조회 네트워크 락 가드

  @override
  void onInit() {
    super.onInit();
    
    if (Get.arguments != null && Get.arguments is GroupModel) {
      currentGroup = Get.arguments as GroupModel;
      
      // 1단계: 이전 페이지에서 넘겨준 최소 정보 선바인딩
      groupName.value = currentGroup!.title;
      masterNickname.value = currentGroup!.authorName.isNotEmpty ? currentGroup!.authorName : 'summer';
      description.value = currentGroup!.description ?? '';
          
      // 2단계: 최신 상세조회 스펙 API 전격 기동!
      fetchGroupDetail();
    } else {
      // Fallback
      groupName.value = 'HECHI';
      masterNickname.value = 'summer';
      description.value = 'HECHI 그룹 정보가 존재하지 않습니다.';
    }
  }

  /// 📡 [실전 API 연동] 그룹 상세 조회 (GET /groups/{groupId})
  Future<void> fetchGroupDetail() async {
    if (currentGroup == null) return;
    
    try {
      isPageLoading.value = true;
      final storage = GetStorage();
      final String? token = storage.read('access_token');
      
      final headers = {
        'accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('📡 [그룹 상세 조회 요청] URL: $serverBaseUrl/groups/${currentGroup!.id}');
      final response = await _connect.get(
        '$serverBaseUrl/groups/${currentGroup!.id}',
        headers: headers,
      );

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body;
        
        // 1. 기본 텍스트 정보 정밀 동적 맵핑
        groupName.value = data['name'] ?? '';
        description.value = data['description'] ?? '설명이 없습니다.';
        masterNickname.value = data['leaderName'] ?? '여름';
        isPublic.value = !(data['isPrivate'] ?? false);
        
        // 2. 가입 상태 실시간 스위칭 가드 동기화
        isAlreadyJoined.value = data['isJoined'] ?? false;

        // 3. 인원수 바인딩 (예: "4/200")
        final int currentCount = data['memberCount'] ?? 0;
        final int maxMembers = data['maxMembers'] ?? 0;
        memberCount.value = '$currentCount/$maxMembers';

        // 4. 날짜 포맷팅 가공 (2026-05-18T17:35:10 -> 26.05.18)
        final String rawDate = data['createdAt'] ?? '';
        if (rawDate.length >= 10) {
          final year = rawDate.substring(2, 4);
          final month = rawDate.substring(5, 7);
          final day = rawDate.substring(8, 10);
          createdDate.value = '$year.$month.$day';
        } else {
          createdDate.value = '26.05.18';
        }

        // 5. 📚 [미션 책 목록 매핑] 서버에서 받아온 고화질 썸네일과 타이틀 바인딩
        final List<dynamic> rawBooks = data['missionBooks'] ?? [];
        books.value = rawBooks.map((b) {
          return {
            'title': b['title']?.toString() ?? '제목 없음',
            'image': b['thumbnail']?.toString() ?? '',
          };
        }).toList();

        print('✅ [상세조회 동기화 성공] 방이름: ${groupName.value}, 미션도서: ${books.length}권');
      } else {
        print('❌ 그룹 상세 조회 API 에러코드: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 그룹 상세 조회 네트워크 통신 중 예외 발생: $e');
    } finally {
      isPageLoading.value = false;
    }
  }

  void toggleGroupType() {
    isPublic.value = !isPublic.value;
  }

  void joinGroup() {
    Get.back();
    Get.snackbar('알림', '${groupName.value} 그룹 가입이 완료되었습니다.', snackPosition: SnackPosition.BOTTOM);
    
    if (Get.isRegistered<MyGroupController>()) {
      Get.find<MyGroupController>().fetchMyGroups();
    }
    // 가입 완료 후 상태 반영 리프레시
    fetchGroupDetail();
  }

  /// 🚪 [실전 API 연동] 그룹 탈퇴하기 (DELETE /groups/{groupId}/leave)
  void leaveGroup() {
    if (currentGroup == null) return;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '\'${groupName.value}\' 그룹을 탈퇴하시겠습니까?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F3F3F)),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '탈퇴 시 해당 그룹의 게시판 확인 및\n미션 참여가 제한됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.4),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Get.back();
                        await _sendLeaveGroupApi(); 
                      },
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: const Center(
                        child: Text('예', style: TextStyle(fontSize: 16, color: Color(0xffE26A6A), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        print('❌ 그룹 탈퇴 취소됨');
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      child: const Center(
                        child: Text('아니오', style: TextStyle(fontSize: 16, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _sendLeaveGroupApi() async {
    final GetConnect connect = GetConnect();
    final storage = GetStorage();

    try {
      final String? token = storage.read('access_token');
      final headers = {
        'accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('📡 [탈퇴 요청] URL: $serverBaseUrl/groups/${currentGroup!.id}/leave');
      final response = await connect.delete(
        '$serverBaseUrl/groups/${currentGroup!.id}/leave',
        headers: headers,
      );

      if (response.statusCode == 200 && response.body != null) {
        final bool isSuccess = response.body['ok'] ?? false;
        
        if (isSuccess) {
          print('✅ [서버 통신 성공] 그룹 탈퇴 처리 완료');
          
          if (Get.isRegistered<MyGroupController>()) {
            final myGroupCtrl = Get.find<MyGroupController>();
            myGroupCtrl.myGroups.removeWhere((g) => g.id == currentGroup!.id);
            await myGroupCtrl.fetchMyGroups();
          }

          Get.back();

          Get.snackbar(
            '탈퇴 완료', 
            '\'${groupName.value}\' 그룹에서 안전하게 탈퇴되었습니다.', 
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            margin: const EdgeInsets.all(20),
          );
        }
      } else {
        print('❌ 그룹 탈퇴 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 그룹 탈퇴 통신 에러: $e');
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}