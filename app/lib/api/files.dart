import 'dart:convert';

import 'package:app/api/account.dart';
import 'package:app/api/http_interface.dart';
import 'package:app/api/types.dart';
import 'package:app/util/url.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

Future<List<FileResponse>?> getFiles(String? clientEmail) async {
  final response = await requestGet(
    '/api/file/list',
    {
      'email': clientEmail ?? (await getCurrentEmail() ?? ''),
    },
    await authHeader(),
  );

  GetFilesResponse? getFilesResponse;
  try {
    final json = jsonDecode(response.body);
    getFilesResponse = GetFilesResponse.fromJson(json);
  } catch (e) {
    print('Failed to get files: $e');
  }

  return getFilesResponse?.files;
}

Future<bool> uploadFile(
  PlatformFile file,
  String fileType,
  String? clientEmail,
) async {
  final uri = Uri.parse('${await getApiUrl()}/api/file/upload');

  final request = http.MultipartRequest('POST', uri)
    ..files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name))
    ..fields['email'] = clientEmail ?? (await getCurrentEmail() ?? '')
    ..fields['file_type'] = fileType
    ..headers.addAll(await authHeader());

  final response = await request.send();
  final body = await response.stream.bytesToString();
  final json = jsonDecode(body);

  if (response.statusCode == 200 && json['success'] == true) {
    return true;
  } else {
    final err = json['error'] ?? 'Upload failed';
    print('Failed to upload file: $err');
    return false;
  }
}

Future<bool> deleteFile(String id) async {
  final uri = Uri.parse('${await getApiUrl()}/api/file?id=$id');
  final response = await http.delete(
    uri,
    headers: await authHeader(),
  );

  final json = jsonDecode(response.body);
  if (response.statusCode == 200 && json['success'] == true) {
    return true;
  } else {
    final err = json['error'] ?? 'Delete failed';
    print('Failed to delete file: $err');
    return false;
  }
}

Future<String> getFileUrl(String id) async {
  return '${await getApiUrl()}/api/file?id=$id';
}
