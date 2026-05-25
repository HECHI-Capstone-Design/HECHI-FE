import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';

class GroupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupController>(() => GroupController(), fenix: true);
  }
}