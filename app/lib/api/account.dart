import 'dart:convert';

import 'package:app/api/types.dart';
import 'package:app/api/http_interface.dart';
import 'package:app/signup.dart';
import 'package:app/util/url.dart';
import 'package:app/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _prefInstance;
Future<SharedPreferences> _getPrefInstance() async {
  _prefInstance ??= await SharedPreferences.getInstance();
  return _prefInstance!;
}

String kEmailPrefKey = "qrhome_email";
String kAuthPrefKey = "qrhome_auth";
String kAccountTypePrefKey = "qrhome_acc_type";

const String kAccountTypeClient = "CLIENT";
const String kAccountTypeCaseWorker = "CASE_WORKER";

Future<String?> getCurrentEmail() async {
  return _getPrefInstance().then((prefs) => prefs.getString(kEmailPrefKey));
}

Future<String?> getCurrentAuth() async {
  return _getPrefInstance().then((prefs) => prefs.getString(kAuthPrefKey));
}

Future<String?> getCurrentAccountType() async {
  return _getPrefInstance()
      .then((prefs) => prefs.getString(kAccountTypePrefKey));
}

Future setCurrentEmail(String? email) async {
  return _getPrefInstance().then((prefs) async {
    if (email == null) {
      prefs.remove(kEmailPrefKey);
    } else {
      prefs.setString(kEmailPrefKey, email);
    }
  });
}

Future setCurrentAuth(String? auth) async {
  return _getPrefInstance().then((prefs) async {
    if (auth == null) {
      prefs.remove(kAuthPrefKey);
    } else {
      prefs.setString(kAuthPrefKey, auth);
    }
  });
}

Future setCurrentAccountType(String? type) async {
  return _getPrefInstance().then((prefs) async {
    if (type == null) {
      prefs.remove(kAccountTypePrefKey);
    } else {
      prefs.setString(kAccountTypePrefKey, type);
    }
  });
}

Future<bool> _hasAuthKeys() async {
  return (await getCurrentAuth()) != null && (await getCurrentEmail()) != null;
}

enum HttpMethod { getMethod, postMethod }

class GetAccountLinkResponse {
  final bool success;
  final String code;
  final String error;

  const GetAccountLinkResponse({
    required this.success,
    required this.code,
    required this.error,
  });

  factory GetAccountLinkResponse.fromJson(String raw) {
    return switch (jsonDecode(raw)) {
      {
        'success': bool success,
        'code': String code,
        'error': String error,
      } =>
        GetAccountLinkResponse(success: success, code: code, error: error),
      _ => throw const FormatException('Failed to parse message json'),
    };
  }
}

Future<String?> createAccount(
  String first,
  String last,
  String email,
  String password,
  UserType userType,
  DateTime dob,
) async {
  final response = await requestPost('/api/account/create', {
    'email': email,
    'password': password,
    'first': first,
    'last': last,
    'dob': dateToStringAPI(dob),
    'type': switch (userType) {
      UserType.client => 'CLIENT',
      UserType.caseWorker => 'CASE_WORKER',
      _ => '',
    },
  }, {});

  final resObj = CreateAccountResponse.fromJson(response.body);

  if (resObj != null) {
    if (resObj.success) {
      return null;
    } else {
      print('Failed to create account: ${resObj.error}');
      return resObj.error;
    }
  } else {
    print('Failed to create account. Status code: ${response.statusCode}');
    return 'Failed to create account: ${response.statusCode}';
  }
}

// Function to authenticate the user and store the token in memory
Future<Map<String, dynamic>> authenticateAccount(
    String email, String password) async {
  final response = await requestPost(
    '/api/account/auth',
    {
      'email': email,
      'password': password,
    },
    await authHeader(),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    if (responseData['success']) {
      if (responseData['challenge'] == true) {
        // check api boolean
        return {
          'success': true,
          'requires2FA': true,
          'errorMessage': '',
          'accountType': responseData['type'],
          'email': responseData['email'],
        };
      }
      await setCurrentAuth(responseData['auth_token']);
      await setCurrentEmail(email);
      await setCurrentAccountType(responseData['type']);
      return {
        'success': true,
        'requires2FA': false,
        'errorMessage': '',
        'accountType': responseData['type'],
        'email': responseData['email'],
      };
    } else {
      return {
        'success': false,
        'requires2FA': false,
        'errorMessage': responseData['error']
      };
    }
  } else {
    return {
      'success': false,
      'requires2FA': false,
      'errorMessage': 'Failed to authenticate'
    };
  }
}

Future<bool> verifyTwoFactorCode(String email, String code) async {
  final response = await requestGet(
    '/api/account/validate-2fa',
    {
      'email': email,
      'code': code,
    },
    await authHeader(),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);

    if (responseData['success']) {
      await setCurrentAuth(responseData['auth_token']);
      await setCurrentEmail(email);
      await setCurrentAccountType(responseData['type']);

      return true;
    }
  }
  return false;
}

Future<bool> isAuthorized() async {
  if (!(await _hasAuthKeys())) {
    return false;
  }
  final response = await requestGet(
    '/api/account/validate',
    {},
    await authHeader(),
  );
  final json = jsonDecode(response.body);
  return json['valid'];
}

Future<String?> getLinkUrl() async {
  final response = await requestGet(
    '/api/account/linkcode',
    {},
    await authHeader(),
  );
  // if (response.statusCode != 200) {
  //   print('Invalid response code');
  //   return null;
  // }

  print(response.body);

  GetAccountLinkResponse? link;
  try {
    link = GetAccountLinkResponse.fromJson(response.body);
  } catch (e) {
    print('Failed to get account link');
    return null;
  }

  if (!link.success) {
    print('Error: ${link.error}');
    return null;
  }

  var pageUrl = await getPageUrl();
  final lastSlash = pageUrl.lastIndexOf('/');
  if (lastSlash > 0 && lastSlash != pageUrl.length - 1) {
    pageUrl = pageUrl.substring(0, lastSlash + 1);
  }

  final url = '$pageUrl?link=${link.code}';
  print('Link URL: $url');
  return url;
}

Future<BasicUserInfo?> getAccountLinkCodeMeta(String linkCode) async {
  final response = await requestGet(
    '/api/account/linkcode/meta',
    {'code': linkCode},
    await authHeader(),
  );

  GetAccountLinkMetaResponse? linkMetaResp;
  try {
    linkMetaResp = GetAccountLinkMetaResponse.fromJson(response.body);
  } catch (e) {
    print('Failed to get account link meta');
    print(e);
    return null;
  }

  if (!linkMetaResp.success) {
    print('Error: ${linkMetaResp.error}');
  }

  return linkMetaResp.meta;
}

Future<Map<String, String>> authHeader() async {
  final auth = await getCurrentAuth();
  final email = await getCurrentEmail();
  if (auth != null && email != null) {
    return {
      'QRHome-Auth': auth,
      'QRHome-Email': email,
    };
  } else {
    return {};
  }
}

// function to enable 2fa
Future<bool> enable2FA(String userEmail) async {
  final response = await requestGet(
      '/api/account/enable-2fa', {"email": userEmail}, await authHeader());

  if (response.statusCode == 200) {
    print("2FA enabled for $userEmail"); // debugging output
    return true;
  }

  print("Failed to enable 2FA: ${response.body}");
  return false;
}

Future<bool> check2FAStatus(String userEmail) async {
  final response = await requestGet(
      '/api/account/2fa-status', {"email": userEmail}, await authHeader());

  print(
      "Raw Response: ${response.body}"); // ensure this prints the correct JSON

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    print("Extracted 2FA status: ${json['twoFAEnabled']}"); // debugging output
    return json['twoFAEnabled'] ?? false;
  }

  return false;
}

Future<bool> disable2FA(String userEmail) async {
  final response = await requestGet(
      '/api/account/disable-2fa', {"email": userEmail}, await authHeader());

  if (response.statusCode == 200) {
    print("2FA disabled for $userEmail"); // debugging output
    return true;
  }

  return false;
}

Future<bool> deleteAccount(String userEmail) async {
  final response = await requestPost(
      '/api/account/delete-account', {"email": userEmail}, await authHeader());

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['success'] == true;
  } else {
    return false;
  }
}

Future<bool> linkToClient(String linkCode) async {
  final response = await requestPost(
    '/api/account/link',
    {'link_code': linkCode},
    await authHeader(),
  );

  try {
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when linking with client: ${json['error']}');
      return false;
    }
    return json['success'] ?? false;
  } catch (e) {
    print('Failed to link with client: $e');
  }

  return false;
}

Future<List<BasicUserInfo>?> getLinks() async {
  final response = await requestGet(
    '/api/account/links',
    {},
    await authHeader(),
  );

  GetAccountClientsResponse? clientsResponse;
  try {
    clientsResponse = GetAccountClientsResponse.fromJson(response.body);
  } catch (e) {
    print('Failed to get links: $e');
    return null;
  }

  return clientsResponse.success ? clientsResponse.users : null;
}

Future<bool> unlinkWithUser(String otherEmail) async {
  final response = await requestPost(
    '/api/account/unlink',
    {'other_email': otherEmail},
    await authHeader(),
  );

  try {
    final json = jsonDecode(response.body);
    if ((json['error'] as String? ?? '').isNotEmpty) {
      print('Error when unlinking with user: ${json['error']}');
      return false;
    }
    return json['success'] ?? false;
  } catch (e) {
    print('Failed to unlink with user: $e');
  }

  return false;
}

Future<void> logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(kEmailPrefKey);
  await prefs.remove(kAuthPrefKey);
  await prefs.remove(kAccountTypePrefKey);
  print("Logged out");
}
