import 'dart:convert';
import 'dart:typed_data';
import 'package:hechi/app/config/app_config.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:hechi/features/myGroup/controllers/my_group_controller.dart';

class GroupCreateController extends GetxController {
  final GetConnect _connect = GetConnect();
  final GetStorage _storage = GetStorage();

  static final String baseUrl = AppConfig.baseUrl;

  var groupName = ''.obs;
  var groupId = ''.obs;
  var idCheckStatus = 0.obs;

  // 그룹 프로필 이미지 (웹/모바일 공통: 바이트로 보관)
  var selectedImageBytes = Rxn<Uint8List>();
  var backgroundImageUrl = ''.obs;
  var isUploadingImage = false.obs;

  var maxMembers = RxnInt(); 
  final List<int> memberOptions = [10, 50, 100, 200, 300, 400, 500];

  var groupDescription = ''.obs;
  var isPrivate = false.obs;
  var password = ''.obs;
  var passwordConfirm = ''.obs;

  var isLoading = false.obs;

  /// 갤러리에서 이미지 선택 후 presign 업로드
  Future<void> pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      selectedImageBytes.value = bytes;
      isUploadingImage.value = true;

      final String? token = _storage.read('access_token');
      if (token == null) {
        isUploadingImage.value = false;
        return;
      }

      final filename = 'group_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String? uploadedUrl;

      // Step 1: presign URL 요청
      final presignRes = await _connect.post(
        '$baseUrl/uploads/presign?filename=$filename&contentType=image%2Fjpeg',
        null,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (presignRes.statusCode == 200 && presignRes.body is Map) {
        final body = presignRes.body as Map;
        final String uploadUrl = body['url']?.toString() ?? '';
        final String? publicUrl = body['publicUrl']?.toString();

        final Map<String, String> fields = {};
        final rawFields = body['fields'];
        if (rawFields is Map) {
          rawFields.forEach((k, v) => fields[k.toString()] = v.toString());
        }

        if (uploadUrl.isNotEmpty && publicUrl != null && publicUrl.isNotEmpty) {
          // Step 2: presign url로 파일 업로드
          final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
          fields.forEach((k, v) => request.fields[k] = v);
          request.files.add(http.MultipartFile.fromBytes(
            'file', bytes,
            filename: filename,
            contentType: MediaType('image', 'jpeg'),
          ));
          final uploadRes = await http.Response.fromStream(await request.send());

          if (uploadRes.statusCode >= 200 && uploadRes.statusCode < 300) {
            uploadedUrl = publicUrl;
          }
        }
      }

      // 눈속임 금지: 업로드가 실제로 성공했을 때만 URL을 저장한다.
      // 실패 시 가짜(로컬/blob) 경로를 쓰지 않고 미리보기도 되돌린 뒤 정직하게 알린다.
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        selectedImageBytes.value = null;
        backgroundImageUrl.value = '';
        Get.snackbar('업로드 실패', '이미지 업로드에 실패했습니다. 다시 시도해주세요.');
        return;
      }

      backgroundImageUrl.value = uploadedUrl;
      print('📸 최종 backgroundImageUrl: ${backgroundImageUrl.value}');
    } catch (e) {
      print('📸 이미지 업로드 오류: $e');
      selectedImageBytes.value = null;
      backgroundImageUrl.value = '';
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
        // 이미지는 backgroundImage 필드로 서버에 저장되므로 별도 로컬 캐시를 두지 않는다.

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