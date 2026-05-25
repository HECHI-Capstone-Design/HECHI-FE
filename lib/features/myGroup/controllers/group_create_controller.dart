import 'package:flutter/material.dart'; // 만약 누락되어 있다면 함께 추가
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hechi/features/myGroup/controllers/my_group_controller.dart';

class GroupCreateController extends GetxController {
  final GetConnect _connect = GetConnect();
  final GetStorage _storage = GetStorage();

  static const String baseUrl = 'https://api.43-202-101-63.sslip.io';

  var groupName = ''.obs;
  var groupId = ''.obs;
  var idCheckStatus = 0.obs;

  var maxMembers = RxnInt(); 
  final List<int> memberOptions = [10, 50, 100, 200, 300, 400, 500];

  var groupDescription = ''.obs;
  var isPrivate = false.obs;
  var password = ''.obs;
  var passwordConfirm = ''.obs;

  var isLoading = false.obs;

  void checkDuplicateId(String id) {
    if (id.isEmpty) {
      idCheckStatus.value = 0;
      return;
    }
    if (id.toLowerCase() == 'hechi') {
      idCheckStatus.value = 2; 
    } else {
      idCheckStatus.value = 1; 
    }
  }

  void setMaxMembers(int count) {
    maxMembers.value = count;
  }

  void togglePrivate(bool val) {
    isPrivate.value = val;
    if (!val) {
      password.value = '';
      passwordConfirm.value = '';
    }
  }

  /// 🌐 그룹 생성 (POST /groups)
  Future<void> createGroup() async {
    if (groupName.value.isEmpty || groupId.value.isEmpty || maxMembers.value == null) {
      Get.snackbar('입력 오류', '그룹 이름, ID, 최대 인원을 모두 지정해주세요.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (isPrivate.value && (password.value.isEmpty || password.value != passwordConfirm.value)) {
      Get.snackbar('비밀번호 오류', '비밀번호가 일치하지 않거나 입력되지 않았습니다.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;

      final String? token = _storage.read('access_token');
      print('🔑 현재 보낼 토큰 상태: $token'); 
      final headers = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = {
        "name": groupName.value,
        "groupId": groupId.value,
        "backgroundImage": "string", 
        "maxMembers": maxMembers.value,
        "description": groupDescription.value.isNotEmpty ? groupDescription.value : "그룹 설명입니다.",
        "isPrivate": isPrivate.value,
        "password": isPrivate.value ? password.value : "string", 
        "passwordConfirm": isPrivate.value ? passwordConfirm.value : "string"
      };

      final response = await _connect.post('$baseUrl/groups', body, headers: headers);

      if (response.statusCode == 201) {
        print('✅ 그룹 생성 성공: ${response.body}');
        
        // 갱신 호출 안전하게 분리
        if (Get.isRegistered<MyGroupController>()) {
          final myGroupCtrl = Get.find<MyGroupController>();
          myGroupCtrl.fetchRecommendedGroups(); 
          myGroupCtrl.fetchMyGroups();
        }

        Get.back(); // 💡 줄바꿈 및 스낵바 노출 복구
        Get.snackbar('성공', '${groupName.value} 그룹이 생성되었습니다.', snackPosition: SnackPosition.BOTTOM);
      } else if (response.statusCode == 422) {
        print('❌ Validation Error: ${response.body}');
        Get.snackbar('생성 실패', '입력 데이터 형식 오류가 발생했습니다. (422)', snackPosition: SnackPosition.BOTTOM);
      } else {
        print('❌ 그룹 생성 실패: ${response.statusText} (${response.statusCode})');
        Get.snackbar('에러', '그룹을 생성하지 못했습니다. 다시 시도해 주세요.', snackPosition: SnackPosition.BOTTOM);
      }

    } catch (e) {
      print('❌ 그룹 생성 중 통신 오류 발생: $e');
      Get.snackbar('오류', '서버와 통신하는 중 문제가 발생했습니다.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}