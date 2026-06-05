import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';

class CollectionDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CollectionDetailController>(() => CollectionDetailController(), fenix: true);
  }
}