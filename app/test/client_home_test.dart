import 'dart:convert';

import 'package:app/api/http_interface.dart' as http_interface;
import 'package:app/client_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    http_interface
        .setMockHandler((Uri uri, String method, Map<String, Object?>? _) {
      return switch (uri.path) {
        '/api/account/linkcode' => (
            200,
            jsonEncode({
              'success': true,
              'code': '123456',
              'error': '',
            })
          ),
        _ => null,
      };
    });
  });

  tearDownAll(() {
    http_interface.setMockHandler(null);
  });

  testWidgets('Client Home Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(qrHomeApp(startPage: ClientHome()));
    await tester.pumpAndSettle();
    expect(find.bySubtype<QrImageView>(), findsExactly(1));
  });
}
