import 'package:get/get.dart';

class GroupCreateController extends GetxController {
  // 상태 변수
  var groupName = ''.obs;
  var groupId = ''.obs;

  // 0: 확인 전, 1: 사용 가능, 2: 중복(이미 있음)
  var idCheckStatus = 0.obs;

  var maxMembers = RxnInt(); // null 허용 정수
  final List<int> memberOptions = [10, 50, 100, 200, 300, 400, 500];

  var groupDescription = ''.obs;
  var isPrivate = false.obs;
  var password = ''.obs;
  var passwordConfirm = ''.obs;

  // 아이디 중복 확인 함수
  void checkDuplicateId(String id) {
    if (id.isEmpty) {
      idCheckStatus.value = 0;
      return;
    }
    // TODO: Replace dummy data with API response
    // 임시 로직: 'hechi'라는 아이디는 중복으로 처리, 나머지는 사용 가능
    if (id.toLowerCase() == 'hechi') {
      idCheckStatus.value = 2; // 이미 있는 아이디
    } else {
      idCheckStatus.value = 1; // 사용 가능한 아이디
    }
  }

  // 최대 인원 설정
  void setMaxMembers(int count) {
    maxMembers.value = count;
  }

  // 비공개 설정 토글
  void togglePrivate(bool val) {
    isPrivate.value = val;
    if (!val) {
      password.value = '';
      passwordConfirm.value = '';
    }
  }

  // 그룹 생성
  void createGroup() {
    // TODO: Replace dummy data with API response
    print('그룹 생성 API 호출: ${groupName.value}, ${groupId.value}, 인원: ${maxMembers.value}, 비공개: ${isPrivate.value}');
    Get.back(); // 생성 후 이전 화면으로 이동
  }
}