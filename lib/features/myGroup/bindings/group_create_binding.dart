import 'package:get/get.dart';
import '../controllers/group_create_controller.dart';

class GroupCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupCreateController>(() => GroupCreateController());
  }
}