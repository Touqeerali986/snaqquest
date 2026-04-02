import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}/$normalizedPath',
    );
  }

  Future<Map<String, String>> _headers({String? accessToken}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  dynamic _tryParseJson(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(response.body);
    } on FormatException {
      return null;
    }
  }

  dynamic _parseBody(http.Response response) {
    final payload = _tryParseJson(response);
    if (payload != null || response.body.isEmpty) {
      return payload;
    }
    throw ApiException(
      'Server returned an invalid response format',
      statusCode: response.statusCode,
    );
  }

  Never _throwApiError(http.Response response) {
    final payload = _tryParseJson(response);
    String message = 'Request failed (${response.statusCode})';
    if (payload is Map<String, dynamic>) {
      if (payload['detail'] is String) {
        message = payload['detail'] as String;
      } else {
        final firstKey = payload.keys.isNotEmpty ? payload.keys.first : null;
        final firstValue = firstKey != null ? payload[firstKey] : null;
        if (firstValue is List && firstValue.isNotEmpty) {
          message = firstValue.first.toString();
        } else if (firstValue is String) {
          message = firstValue;
        }
      }
    } else if (response.body.isNotEmpty &&
        response.body.contains('<!doctype html')) {
      message =
          'Server error on backend. Check deployment logs and migrations.';
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(accessToken: accessToken),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBody(response);
    }
    _throwApiError(response);
  }

  Future<dynamic> getJson(String path, {String? accessToken}) async {
    final response = await http.get(
      _uri(path),
      headers: await _headers(accessToken: accessToken),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBody(response);
    }
    _throwApiError(response);
  }

  Future<dynamic> patchMultipart(
    String path, {
    required Map<String, String> fields,
    String? filePath,
    String fileField = 'avatar',
    String? accessToken,
  }) async {
    final request = http.MultipartRequest('PATCH', _uri(path));
    request.fields.addAll(fields);

    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseBody(response);
    }

    _throwApiError(response);
  }

  Future<void> postNoContent(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(accessToken: accessToken),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    _throwApiError(response);
  }

  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}
