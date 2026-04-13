import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static String _defaultBaseUrl() {
    // Web / Desktop → localhost. Android emulator → 10.0.2.2.
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: (q == null || q.isEmpty) ? null : q,
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final r = await _client.get(_uri(path, query), headers: _headers());
    return _decode(r);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final r = await _client.post(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(r);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final r = await _client.put(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(r);
  }

  Future<void> delete(String path) async {
    final r = await _client.delete(_uri(path), headers: _headers());
    if (r.statusCode >= 400) {
      throw ApiException(r.statusCode, _errorMessage(r));
    }
  }

  /// multipart/form-data илгээх. [fields] нь текст талбарууд; [fileField] нь
  /// файлын нэр + контент.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileFieldName,
    required String fileName,
    required List<int> fileBytes,
    String? fileContentType,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    req.fields.addAll(fields);
    req.files.add(
      http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileName,
        contentType: fileContentType == null
            ? null
            : _parseMediaType(fileContentType),
      ),
    );
    final streamed = await _client.send(req);
    final r = await http.Response.fromStream(streamed);
    return _decode(r);
  }

  MediaType? _parseMediaType(String ct) {
    try {
      return MediaType.parse(ct);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(utf8.decode(r.bodyBytes));
    }
    throw ApiException(r.statusCode, _errorMessage(r));
  }

  String _errorMessage(http.Response r) {
    try {
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (body is Map && body['message'] is String) return body['message'];
      if (body is Map && body['error'] is String) return body['error'];
    } catch (_) {}
    return r.body.isEmpty ? 'HTTP ${r.statusCode}' : r.body;
  }

  void close() => _client.close();
}
