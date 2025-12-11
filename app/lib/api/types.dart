import 'dart:convert';

import 'package:app/form/classes.dart';
import 'package:http/http.dart';

class CreateAccountResponse {
  final bool success;
  final String error;

  const CreateAccountResponse({
    required this.success,
    required this.error,
  });

  static CreateAccountResponse? fromJson(jsonStr) {
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return switch (json) {
      {
        'success': bool success,
        'error': String error,
      } =>
        CreateAccountResponse(success: success, error: error),
      _ => null,
    };
  }
}

class BasicUserInfo {
  final String firstName;
  final String lastName;
  final String email;

  const BasicUserInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
  });
}

class GetAccountLinkMetaResponse {
  final bool success;
  final BasicUserInfo? meta;
  final String error;

  const GetAccountLinkMetaResponse({
    required this.success,
    required this.meta,
    required this.error,
  });

  factory GetAccountLinkMetaResponse.fromJson(String raw) {
    return switch (jsonDecode(raw)) {
      {
        'success': bool success,
        'first_name': String firstName,
        'last_name': String lastName,
        'email': String email,
        'error': String error,
      } =>
        GetAccountLinkMetaResponse(
          success: success,
          meta: success
              ? BasicUserInfo(
                  firstName: firstName, lastName: lastName, email: email)
              : null,
          error: error,
        ),
      _ => throw const FormatException('Failed to parse message json'),
    };
  }
}

class GetAccountClientsResponse {
  final bool success;
  final List<BasicUserInfo> users;
  final String error;

  const GetAccountClientsResponse({
    required this.success,
    required this.users,
    required this.error,
  });

  factory GetAccountClientsResponse.fromJson(String raw) {
    return switch (jsonDecode(raw)) {
      {
        'success': bool success,
        'users': List<dynamic> users,
        'error': String error,
      } =>
        GetAccountClientsResponse(
          success: success,
          users: success
              ? users
                  .map((user) => BasicUserInfo(
                        firstName: user['first_name'],
                        lastName: user['last_name'],
                        email: user['email'],
                      ))
                  .toList()
              : [],
          error: error,
        ),
      _ => throw const FormatException('Failed to parse message json'),
    };
  }
}

class GetAccountDataResponse {
  final bool success;
  final String error;
  final bool hasData;
  final ApplicationData applicationData;

  const GetAccountDataResponse({
    required this.success,
    required this.error,
    required this.hasData,
    required this.applicationData,
  });

  factory GetAccountDataResponse.fromJson(String raw) {
    final json = jsonDecode(raw);
    return switch (json) {
      {
        'success': bool success,
        'error': String error,
        'has_data': bool hasData,
        'data': Map<String, dynamic> data,
      } =>
        GetAccountDataResponse(
          success: success,
          error: error,
          hasData: hasData,
          applicationData: ApplicationData.fromJson(data),
        ),
      _ => throw const FormatException('Failed to parse message json'),
    };
  }
}

class FileResponse {
  final String id;
  final String fileName;
  final String fileType;
  final String mimeType;

  const FileResponse({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.mimeType,
  });

  factory FileResponse.fromJson(dynamic json) {
    return switch (json) {
      {
        'id': String id,
        'filename': String fileName,
        'file_type': String fileType,
        'mime_type': String mimeType,
      } =>
        FileResponse(
          id: id,
          fileName: fileName,
          fileType: fileType,
          mimeType: mimeType,
        ),
      _ => throw FormatException("Failed to parse file response"),
    };
  }
}

class GetFilesResponse {
  final bool success;
  final String error;
  final List<FileResponse> files;

  const GetFilesResponse({
    required this.success,
    required this.error,
    required this.files,
  });

  factory GetFilesResponse.fromJson(dynamic json) {
    return GetFilesResponse(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String? ?? '',
      files: (json['files'] as List<dynamic>? ?? [])
          .map((file) => FileResponse.fromJson(file))
          .toList(),
    );
  }
}
