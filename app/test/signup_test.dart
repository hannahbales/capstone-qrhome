// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:io';

import 'package:app/components/buttons.dart';
import 'package:app/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/api/http_interface.dart' as http_interface;

import 'package:app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    http_interface
        .setMockHandler((Uri uri, String method, Map<String, Object?>? _) {
      return switch (uri.path) {
        '/api/account/create' => (
            200,
            jsonEncode({
              'success': true,
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

  tearDown(() {
    setDatePickerMock(null);
  });

  testWidgets('Signup - Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(qrHomeApp());
    await tester.pumpAndSettle(Duration(seconds: 1));

    expect(find.text('QRHome'), findsAny);
    expect(find.text('Sign Up'), findsNothing);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up'), findsAtLeast(1));
    expect(find.text('QRHome'), findsNothing);

    expect(find.byType(TextField), findsAtLeast(5));
    expect(find.byType(DropdownButtonFormField<UserType>), findsOne);
    expect(find.byType(QFilledButton), findsOne);
    expect(find.byType(TextButton), findsOne);
    expect(find.byType(OutlinedButton), findsOne);
  });

  testWidgets('Signup - Success Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(qrHomeApp());
    await tester.pumpAndSettle(Duration(seconds: 1));
    await tester.tap(find.text("Create an Account"));
    await tester.pumpAndSettle();

    setDatePickerMock(() => DateTime(1999));

    await tester.enterText(
      find.ancestor(
        of: find.text('First Name'),
        matching: find.byType(TextField),
      ),
      'John',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Last Name'),
        matching: find.byType(TextField),
      ),
      'Doe',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Email'),
        matching: find.byType(TextField),
      ),
      'a@a.com',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextField),
      ),
      '@helloWorld123',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Confirm Password'),
        matching: find.byType(TextField),
      ),
      '@helloWorld123',
    );

    await tester.tap(find.byType(DropdownButtonFormField<UserType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Client').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Date of Birth'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(QFilledButton));
    await tester.pumpAndSettle();

    // while (tester.widgetList(find.byType(SnackBar)).isEmpty) {
    //   await tester.pump();
    // }

    // final snackbar = tester.widget(find.byType(SnackBar)) as SnackBar;
    // expect(snackbar.backgroundColor, equals(Colors.green[400]));

    expect(find.text('QRHome'), findsAny);
    // expect(find.text('Sign Up'), findsNothing);
  });

  testWidgets('Signup - Bad Email Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(qrHomeApp());
    await tester.pumpAndSettle(Duration(seconds: 1));
    await tester.tap(find.text("Create an Account"));
    await tester.pumpAndSettle();

    setDatePickerMock(() => DateTime(1999));

    await tester.enterText(
      find.ancestor(
        of: find.text('First Name'),
        matching: find.byType(TextField),
      ),
      'John',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Last Name'),
        matching: find.byType(TextField),
      ),
      'Doe',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Email'),
        matching: find.byType(TextField),
      ),
      'a.com',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextField),
      ),
      '@helloWorld123',
    );
    await tester.enterText(
      find.ancestor(
        of: find.text('Confirm Password'),
        matching: find.byType(TextField),
      ),
      '@helloWorld123',
    );

    await tester.tap(find.byType(DropdownButtonFormField<UserType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Client').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Date of Birth'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(QFilledButton));
    await tester.pumpAndSettle(Duration(milliseconds: 500));

    final snackbar = tester.widget(find.byType(SnackBar)) as SnackBar;
    expect(snackbar.backgroundColor, isSameColorAs(Colors.red[400]!));
  });
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
