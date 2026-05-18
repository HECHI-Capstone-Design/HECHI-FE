import 'package:get/get.dart';
import '../controllers/my_group_controller.dart';

class GroupRecommendationBinding extends Bindings {
  @override
  void dependencies() {
    // 이미 메인에서 생성된 컨트롤러를 찾아서 사용 (없으면 생성)
    Get.put(MyGroupController());
  }
}