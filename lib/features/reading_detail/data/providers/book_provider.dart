import 'package:get/get.dart';
import 'package:hechi/app/config/app_config.dart';
import '../models/book_detail_model.dart';
import 'package:get_storage/get_storage.dart';


class BookProvider extends GetConnect {
  BookProvider() {
    httpClient.baseUrl = AppConfig.baseUrl;
  }
  final box = GetStorage();

  Future<BookDetailModel?> getBookDetail(int bookId) async {
    final response = await get('/books/$bookId');

    if (response.status.hasError) {
      print("Book API Error: ${response.statusText}");
      return null;
    } else {
      return BookDetailModel.fromJson(response.body);
    }
  }
}