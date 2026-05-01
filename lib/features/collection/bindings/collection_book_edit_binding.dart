import 'package:get/get.dart';
import '../controllers/collection_book_edit_controller.dart';

class CollectionBookEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CollectionBookEditController>(
          () => CollectionBookEditController(),
    );
  }
}