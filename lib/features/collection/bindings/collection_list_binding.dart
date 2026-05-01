import 'package:get/get.dart';
import '../controllers/collection_list_controller.dart';

class CollectionListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CollectionListController>(() => CollectionListController());
  }
}