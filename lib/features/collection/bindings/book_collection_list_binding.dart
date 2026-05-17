import 'package:get/get.dart';
import '../controllers/book_collection_list_controller.dart';

class BookCollectionListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookCollectionListController>(
          () => BookCollectionListController(),
    );
  }
}