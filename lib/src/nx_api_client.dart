import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models.dart';

/// API client for Nexacon messaging REST endpoints
class NxApiClient {
  final String apiKey;
  final String secretKey;
  final String baseUrl;
  final Duration timeout;

  late final http.Client _httpClient;
  String? _nxToken;

  NxApiClient({
    required this.apiKey,
    required this.secretKey,
    this.baseUrl = 'https://nxservice.quantumvision-tech.com/api/v1.0',
    this.timeout = const Duration(seconds: 30),
  }) {
    _httpClient = http.Client();
  }

  void setToken(String token) {
    _nxToken = token;
  }

  String? getToken() => _nxToken;

  Future<Map<String, dynamic>> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) async {
    final stringParams = params?.map(
      (key, value) => MapEntry(key, value?.toString()),
    );
    final url = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: stringParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Secret-Key': secretKey,
    };

    if (_nxToken != null) {
      headers['X-NX-Token'] = _nxToken!;
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(url, headers: headers)
              .timeout(timeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(url, headers: headers, body: json.encode(data))
              .timeout(timeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(url, headers: headers, body: json.encode(data))
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(
                url,
                headers: headers,
                body: data != null ? json.encode(data) : null,
              )
              .timeout(timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }

    if (response.statusCode >= 400) {
      throw Exception(
        'API request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Get NX token for a user
  Future<Map<String, dynamic>> getNxToken(String username) async {
    final res = await request(
      'POST',
      '/nexacon-auth/nxm-token/',
      data: {'username': username, 'host': 'nxservice.quantumvision-tech.com'},
    );
    _nxToken = res['token'] as String?;
    return res;
  }

  /// Refresh NX token
  Future<Map<String, dynamic>> refreshNxToken(String refreshToken) async {
    final res = await request(
      'POST',
      '/nexacon-auth/nxm-token/refresh/',
      data: {'refresh_token': refreshToken},
    );
    _nxToken = res['token'] as String?;
    return res;
  }

  /// Fetch message history
  Future<NxMessageHistoryResponse> getMessageHistory({
    String? peer,
    int page = 1,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': pageSize};

    if (peer != null && peer.isNotEmpty) {
      params['peer'] = peer;
    }

    if (startDate != null) {
      params['start_date'] =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }

    if (endDate != null) {
      params['end_date'] =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }

    final response = await request('GET', '/nx/history/', params: params);
    return NxMessageHistoryResponse.fromJson(response);
  }

  /// Get presence for a user
  Future<Map<String, dynamic>> getPresence([String? user]) async {
    final params = <String, dynamic>{};
    if (user != null) params['user'] = user;
    return request('GET', '/nx/presence/', params: params);
  }

  void close() {
    _httpClient.close();
  }
}
