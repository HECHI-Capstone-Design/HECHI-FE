import 'package:get/get.dart';
import '../controllers/my_group_controller.dart';

class MyGroupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyGroupController>(() => MyGroupController());
  }
}