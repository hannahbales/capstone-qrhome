import 'dart:convert';

import 'package:app/api/account.dart';
import 'package:app/api/http_interface.dart';
import 'package:app/form/classes.dart';

Future<List<FamilyMember>> getFamilyMembers(String? clientEmail) async {
  final response = await requestGet(
    '/api/data/family',
    {'email': clientEmail ?? (await getCurrentEmail() ?? '')},
    await authHeader(),
  );

  try {
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when unlinking with user: ${json['error']}');
      return [];
    }

    List<FamilyMember> familyMembers = [];
    for (final member in (json['family'] as List<dynamic>)) {
      familyMembers.add(FamilyMember.fromJson(member));
    }

    return familyMembers;
  } catch (e) {
    print('Failed to unlink with user: $e');
  }

  return [];
}

Future<bool> addFamilyMember(FamilyMember member) async {
  final response = await requestPost(
    '/api/data/family/create',
    {
      'data': member.toJson(),
    },
    await authHeader(),
  );

  try {
    print('Response: ${response.body}');
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when adding family member: ${json['error']}');
      return false;
    }

    if (json['success'] ?? false) {
      member.id = json['id']!;
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print('Failed to add family member: $e');
  }

  return false;
}

Future<bool> updateFamilyMember(FamilyMember member) async {
  final response = await requestPost(
    '/api/data/family/update',
    {
      'data': member.toJson(),
    },
    await authHeader(),
  );

  try {
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when updating family member: ${json['error']}');
      return false;
    }

    return json['success'] ?? false;
  } catch (e) {
    print('Failed to update family member: $e');
  }

  return false;
}

Future<bool> deleteFamilyMember(int id) async {
  final response = await requestPost(
    '/api/data/family/delete',
    {'id': id},
    await authHeader(),
  );

  try {
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when deleting family member: ${json['error']}');
      return false;
    }

    return json['success'] ?? false;
  } catch (e) {
    print('Failed to delete family member: $e');
  }

  return false;
}
