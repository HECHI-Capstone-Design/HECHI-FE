import 'package:get/get.dart';
import '../controllers/add_to_collection_controller.dart';

class AddToCollectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddToCollectionController>(
          () => AddToCollectionController(),
    );
  }
}