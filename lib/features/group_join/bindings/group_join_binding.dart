import 'package:get/get.dart';
import '../controllers/group_join_controller.dart';

class GroupJoinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupJoinController>(() => GroupJoinController());
  }
}