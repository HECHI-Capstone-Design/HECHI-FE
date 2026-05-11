import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';

// 화면이 열릴 때 컨트롤러를 메모리에 올려주는 연결고리입니다.
class CollectionDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CollectionDetailController>(() => CollectionDetailController());
  }
}