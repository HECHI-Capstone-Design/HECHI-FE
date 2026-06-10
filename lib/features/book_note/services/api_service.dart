import 'dart:convert';
import 'package:hechi/app/config/app_config.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final box = GetStorage();

  final String baseUrl = AppConfig.baseUrl;

  /// ====================== GET ======================
  Future<dynamic> get(String endpoint) async {
    final token = box.read("access_token");

    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response);
  }

  /// ====================== POST ======================
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final token = box.read("access_token");

    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  /// ====================== PUT ======================
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final token = box.read("access_token");

    final response = await http.put(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  /// ====================== DELETE ======================
  Future<dynamic> delete(String endpoint) async {
    final token = box.read("access_token");

    final response = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response);
  }

  /// ====================== Response Handler ======================
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      print("❌ API ERROR: ${response.statusCode}, body=${response.body}");
      throw Exception("API Error: ${response.statusCode}");
    }
  }
}
