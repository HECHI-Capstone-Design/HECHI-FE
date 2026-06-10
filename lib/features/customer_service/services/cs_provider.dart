import 'package:get/get.dart';
import 'package:hechi/app/config/app_config.dart';
import 'package:get_storage/get_storage.dart';

class CsProvider extends GetConnect {
  final _box = GetStorage();
  final String _baseUrl = AppConfig.baseUrl;

  @override
  void onInit() {
    httpClient.baseUrl = _baseUrl;
    httpClient.addRequestModifier<void>((request) async {
      final token = _box.read('access_token');
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });
  }

  Future<Response> getFaqs() => get('/customer-service/faqs');

  Future<Response> getMyTickets() => get('/customer-service/my');

  Future<Response> createTicket(String title, String description) async {
    final formData = FormData({
      'inquiryTitle': title,
      'inquiryDescription': description,
    });
    return post('/customer-service/my', formData);
  }

  Future<Response> getAdminTickets({String? status, int page = 1}) =>
      get('/customer-service/admin', query: {
        if (status != null) 'status_filter': status,
        'page': page.toString(),
      });

  Future<Response> postAdminAnswer(int ticketId, String answer) =>
      post('/customer-service/admin', {
        'ticket_id': ticketId,
        'answer': answer,
      });

  Future<Response> getAdminSummary() => get('/customer-service/admin/summary');

  Future<Response> deleteAdminAnswer(int ticketId) =>
      delete('/customer-service/admin', query: {'ticket_id': ticketId.toString()});
}