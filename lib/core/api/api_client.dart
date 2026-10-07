import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiClient {
  // Android emulator uses 10.0.2.2 to reach your Mac's localhost
  static const String baseUrl = 'http://192.168.1.19:4000/api';
  // If you run on iOS simulator later, use: http://localhost:5000
  // If on Chrome (web), use: http://localhost:5000

  final http.Client _client = http.Client();
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    log('POST $path response: ${res.statusCode} ${res.body}'); // Log the response
    return _handle(res);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    log('PATCH $path request: ${jsonEncode(body)}');
    final res = await _client.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
     // Log the request body
     
    );
    log('PATCH $path response: ${res.statusCode} ${res.body}'); // Log the response
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: res.statusCode,
      message: body['error'] ?? body['message'] ?? 'Something went wrong',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}