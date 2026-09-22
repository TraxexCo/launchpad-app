import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // For Android emulator: http://10.0.2.2/launchpad_api/api
  // For Web/Windows: http://localhost/launchpad_api/api
  // Change based on target device
  static const String baseUrl = 'http://localhost/launchpad_api/api';

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
          if (decoded['status'] == 'error') {
              throw ApiException(decoded['message'] ?? 'Unknown error', response.statusCode);
          }
          if (decoded.containsKey('data')) {
              return decoded['data'];
          }
      }
      return decoded;
    } else {
      String message = 'Server error';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['message'] ?? decoded['error'] ?? 'Server error';
        }
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.put(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    http.Response response;
    if (body != null) {
      // http.delete does not officially support a body in all environments, but it can work
      // A common workaround is building a request manually
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);
      request.body = jsonEncode(body);
      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } else {
      response = await http.delete(uri, headers: headers);
    }
    return _handleResponse(response);
  }
}
