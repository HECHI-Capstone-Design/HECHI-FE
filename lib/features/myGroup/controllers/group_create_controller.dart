import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:hechi/features/myGroup/controllers/my_group_controller.dart';

class GroupCreateController extends GetxController {
  final GetConnect _connect = GetConnect();
  final GetStorage _storage = GetStorage();

  static const String baseUrl = 'https://api.43-202-101-63.sslip.io';

  var groupName = ''.obs;
  var groupId = ''.obs;
  var idCheckStatus = 0.obs;

  // 그룹 프로필 이미지
  var selectedImageFile = Rxn<File>();
  var backgroundImageUrl = ''.obs;
  var isUploadingImage = false.obs;

  var maxMembers = RxnInt(); 
  final List<int> memberOptions = [10, 50, 100, 200, 300, 400, 500];

  var groupDescription = ''.obs;
  var isPrivate = false.obs;
  var password = ''.obs;
  var passwordConfirm = ''.obs;

  var isLoading = false.obs;

  /// 갤러리에서 이미지 선택 후 S3 presign 업로드
  Future<void> pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      selectedImageFile.value = File(picked.path);
      isUploadingImage.value = true;

      final String? token = _storage.read('access_token');
      if (token == null) return;

      final filename = 'group_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Step 1: presign URL 획득
      final presignRes = await _connect.post(
        '$baseUrl/uploads/presign?filename=$filename&contentType=image%2Fjpeg&acl=public-read',
        null,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📸 presign 응답 코드: ${presignRes.statusCode}');
      print('📸 presign 응답 바디: ${presignRes.body}');

      if (presignRes.statusCode == 200) {
        final body = presignRes.body;
        String uploadUrl = '';
        Map<String, String> fields = {};
        String? presignPublicUrl;

        if (body is Map) {
          uploadUrl = body['url']?.toString() ?? '';
          if (uploadUrl.isEmpty) uploadUrl = body['presignedUrl']?.toString() ?? '';
          presignPublicUrl = body['publicUrl']?.toString();

          final rawFields = body['fields'];
          if (rawFields is Map) {
            rawFields.forEach((k, v) => fields[k.toString()] = v.toString());
          }
        }

        print('📸 uploadUrl=$uploadUrl, fields keys=${fields.keys.toList()}, publicUrl=$presignPublicUrl');

        if (uploadUrl.isNotEmpty) {
          // Step 2: S3 multipart POST
          final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
          fields.forEach((k, v) => request.fields[k] = v);
          request.files.add(await http.MultipartFile.fromPath(
              'file', picked.path, filename: filename));
          final s3Res = await request.send();
          print('📸 S3 업로드 결과: ${s3Res.statusCode}');

          if (s3Res.statusCode == 200 || s3Res.statusCode == 204) {
            if (presignPublicUrl != null && presignPublicUrl.isNotEmpty) {
              backgroundImageUrl.value = presignPublicUrl;
            } else {
              // uploadUrl + key 조합 (슬래시 처리)
              final key = fields['key'] ?? filename;
              final base = uploadUrl.endsWith('/') ? uploadUrl : '$uploadUrl/';
              backgroundImageUrl.value = '$base$key';
            }
            print('📸 최종 backgroundImageUrl: ${backgroundImageUrl.value}');
          } else {
            print('📸 S3 업로드 실패: ${s3Res.statusCode} - 로컬 경로 사용');
            backgroundImageUrl.value = picked.path; // 로컬 폴백
          }
        } else {
          print('📸 uploadUrl 없음 - presign 응답 구조 이상');
          backgroundImageUrl.value = picked.path;
        }
      } else {
        print('📸 presign 실패: ${presignRes.statusCode}');
        backgroundImageUrl.value = picked.path; // 로컬 폴백
      }
    } catch (e) {
      print('📸 이미지 업로드 오류: $e');
      Get.snackbar('오류', '이미지 업로드에 실패했습니다.');
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> checkDuplicateId(String id) async {
    if (id.isEmpty) {
      idCheckStatus.value = 0;
      return;
    }
    try {
      final String? token = _storage.read('access_token');
      final response = await _connect.get(
        '$baseUrl/groups/check-id?groupId=${Uri.encodeComponent(id)}',
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final body = response.body;
        // 서버가 { "available": true/false } 또는 200 = 사용가능, 409 = 중복 형태일 수 있음
        final bool available = body is Map
            ? (body['available'] == true)
            : true;
        idCheckStatus.value = available ? 1 : 2;
      } else if (response.statusCode == 409) {
        idCheckStatus.value = 2; // 중복
      } else {
        idCheckStatus.value = 0;
      }
    } catch (e) {
      idCheckStatus.value = 0;
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
    if (idCheckStatus.value != 1) {
      Get.snackbar('아이디 확인 필요', '그룹 아이디 중복 확인을 먼저 해주세요.', snackPosition: SnackPosition.BOTTOM);
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
        "backgroundImage": backgroundImageUrl.value.isNotEmpty ? backgroundImageUrl.value : "",
        "maxMembers": maxMembers.value,
        "description": groupDescription.value.isNotEmpty ? groupDescription.value : "그룹 설명입니다.",
        "isPrivate": isPrivate.value,
        "password": isPrivate.value ? password.value : "string", 
        "passwordConfirm": isPrivate.value ? passwordConfirm.value : "string"
      };

      final response = await _connect.post('$baseUrl/groups', body, headers: headers);

      if (response.statusCode == 201) {
        print('✅ 그룹 생성 성공: ${response.body}');

        // 새 그룹 ID로 이미지 URL을 GetStorage에 저장 (API 응답에 없을 경우 백업)
        if (backgroundImageUrl.value.isNotEmpty) {
          final newGroupId = response.body is Map
              ? (response.body['groupId']?.toString() ?? response.body['id']?.toString())
              : null;
          if (newGroupId != null) {
            _storage.write('group_img_$newGroupId', backgroundImageUrl.value);
            print('📸 GetStorage 저장: group_img_$newGroupId = ${backgroundImageUrl.value}');
          }
        }

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