import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../../features/mainpage/controllers/mainpage_controller.dart';
import '../../features/search/controllers/search_controller.dart';
import '../../features/my_read/controllers/my_read_controller.dart';
import '../../features/reading_registration/controllers/book_stopper_controller.dart';
import '../../features/reading_registration/controllers/hardware_camera_controller.dart';
import '../../features/reading_registration/controllers/reading_registration_controller.dart';
import '../../features/reading_registration/data/repository/reading_registration_repository.dart';
import '../../features/myGroup/controllers/my_group_controller.dart';
import '../../features/notification/controllers/notification_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppController());
    Get.put(MainpageController());
    Get.put(BookSearchController());
    Get.put(MyReadController());
    Get.lazyPut<ReadingRegistrationRepository>(() => ReadingRegistrationRepository());
    Get.put(ReadingRegistrationController(repository: Get.find()));
    Get.put(BookStopperController());
    Get.put(HardwareCameraController());
    Get.put(MyGroupController());
    Get.put(NotificationController());
  }
}
