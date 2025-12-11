import 'dart:convert';

import 'package:app/api/account.dart';
import 'package:app/api/http_interface.dart';
import 'package:app/api/types.dart';
import 'package:app/form/classes.dart';
import 'package:app/util/result.dart';

Future<Result<ApplicationData>> getApplicationData(String email) async {
  final response = await requestGet(
    '/api/data/application',
    {
      'email': email,
    },
    await authHeader(),
  );

  try {
    print(
        'Response: ${JsonEncoder.withIndent('  ').convert(jsonDecode(response.body))}');
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when getting application data: ${json['error']}');
      return Result.error(json['error'] ?? response.statusCode.toString());
    }

    if (json['success'] ?? false) {
      if (json['has_data'] ?? false) {
        return Result.success(ApplicationData.fromJson(
            json['application_data'] as Map<String, dynamic>));
      } else {
        return Result.success(ApplicationData.empty());
      }
    }
  } catch (e) {
    print('Failed to get application data: $e');
  }

  return Result.error('Failed to get application data');
}

Future<bool> updateApplicationData(ApplicationData data) async {
  final response = await requestPost(
    '/api/data/application',
    {
      'application_data': data.toJson(),
    },
    await authHeader(),
  );

  try {
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when setting application data: ${json['error']}');
      return false;
    }

    return json['success'] ?? false;
  } catch (e) {
    print('Failed to set application data: $e');
  }

  return false;
}
