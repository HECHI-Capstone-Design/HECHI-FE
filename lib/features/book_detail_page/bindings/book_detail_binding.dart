import 'package:get/get.dart';
import '../controllers/book_detail_controller.dart';

class BookDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookDetailController>(() => BookDetailController(), fenix: true);
  }
}