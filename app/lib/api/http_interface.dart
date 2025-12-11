import 'dart:convert';

import 'package:app/util/url.dart';
import 'package:http/http.dart' as http;

const String kMethodGet = "get";
const String kMethodPost = "post";

typedef MockHandler = (int, String)? Function(
    Uri uri, String method, Map<String, Object?>? requestBody)?;

MockHandler _mockHandler;

(int, String)? _mockRequest(
    Uri uri, String method, Map<String, Object?>? requestBody) {
  if (_mockHandler == null) return null;
  print('Attempting to mock');
  return _mockHandler!(uri, method, requestBody);
}

void setMockHandler(MockHandler handler) {
  _mockHandler = handler;
}

Future<http.Response> requestGet(
  String endpoint,
  Map<String, String> requestParams,
  Map<String, String> headers,
) async {
  final params = requestParams.isEmpty ? '' : '?${mapParams(requestParams)}';
  final uri = Uri.parse('${await getApiUrl()}$endpoint$params');
  final mockedResponse = _mockRequest(uri, kMethodGet, null);
  if (mockedResponse == null) {
    return await http.Client().get(
      uri,
      headers: headers,
    );
  } else {
    return http.Response(mockedResponse.$2, mockedResponse.$1);
  }
}

Future<http.Response> requestPost(
  String endpoint,
  Map<String, Object?> requestBody,
  Map<String, String> headers,
) async {
  final uri = Uri.parse('${await getApiUrl()}$endpoint');
  final body = jsonEncode(requestBody);
  final mockedResponse = _mockRequest(uri, kMethodPost, requestBody);
  if (mockedResponse == null) {
    return await http.Client().post(uri, body: body, headers: {
      'Content-Type': 'application/json',
      ...headers,
    });
  } else {
    return http.Response(mockedResponse.$2, mockedResponse.$1);
  }
}

String mapParams(Map<String, String> params) {
  return params.entries
      .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
      .join("&");
}
