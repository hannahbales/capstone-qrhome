import 'dart:convert';

import 'package:app/api/account.dart';
import 'package:app/api/http_interface.dart' as http_interface;
import 'package:app/client_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      kEmailPrefKey: 'test@gmail.com',
      kAuthPrefKey: 'test_auth_token',
      kAccountTypePrefKey: kAccountTypeClient,
    });

    http_interface
        .setMockHandler((Uri uri, String method, Map<String, Object?>? _) {
      return switch (uri.path) {
        '/api/account/linkcode' => (
            200,
            jsonEncode(
              {
                'success': true,
                'code': '123456',
                'error': '',
              },
            )
          ),
        '/api/data/application' => (
            200,
            jsonEncode(
              {
                'success': true,
                'error': '',
                'has_data': false,
              },
            )
          ),
        '/api/data/family' => (
            200,
            jsonEncode(
              {
                'success': true,
                'error': '',
                'family': [],
              },
            )
          ),
        _ => null,
      };
    });
  });

  tearDownAll(() {
    http_interface.setMockHandler(null);
  });

  testWidgets('Form Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(qrHomeApp(startPage: ClientHome()));
    await tester.pumpAndSettle();

    final ScaffoldState scaffold = tester.firstState(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('form_button')));
    await tester.pumpAndSettle();
  });
}
