import 'package:app/api/account.dart';
import 'package:app/caseworker_home.dart';
import 'package:app/components/buttons.dart';
import 'package:app/components/loading.dart';
import 'package:app/components/scaffold.dart';
import 'package:app/client_home.dart';
import 'package:app/link_dialog.dart';
import 'package:app/signup.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final dataInputController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final twoFaController = TextEditingController();

  bool loading = true;
  bool requires2FA = false;
  // String? linkCode = 'VWaKjswstCo1';
  String? linkCode;

  void login() async {
    final username = usernameController.text;
    final password = passwordController.text;

    final result = await authenticateAccount(username, password);

    if (result['success'] == true) {
      if (result['requires2FA'] == true) {
        setState(() {
          requires2FA = true; // ensure UI updates
        });
      } else {
        nextPage();
      }
    } else {
      final reason = result['error'] as String? ?? 'Invalid Login';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unsuccessful, $reason'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  void verify2FA() async {
    final username = usernameController.text;
    final code = twoFaController.text;
    final success = await verifyTwoFactorCode(username, code);
    if (success) {
      requires2FA = false;
      print('Login successful after 2FA!');
      nextPage();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unsuccessful, 2FA code not accepted'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  void nextPage() async {
    var accountType = await getCurrentAccountType();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            if (accountType == kAccountTypeCaseWorker && linkCode != null) {
              return LinkDialog(link: linkCode!);
            } else {
              return accountType == kAccountTypeCaseWorker
                  ? CaseworkerHome()
                  : ClientHome();
            }
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    Future(() async {
      if (Uri.base.queryParameters.containsKey('link')) {
        final linkCode = Uri.base.queryParameters['link'];
        if (linkCode != null) this.linkCode = linkCode;
      }

      final isLoggedIn = await isAuthorized();
      if (isLoggedIn) {
        nextPage();
      } else {
        setState(() {
          loading = false;
        });
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return QScaffold(
      title: 'QR Home',
      icon: Icon(Icons.home, size: 30, color: Colors.white),
      body: loading
          ? qLoadingWidget()
          : Stack(
              children: [
                // Background gradient container
                Container(
                  decoration: BoxDecoration(color: Color(0xFF75A9F9)),
                  // Other container properties
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 100.0,
                      left: 10.0,
                      right: 10.0,
                    ),
                    child: Column(
                      spacing: 10,
                      children: [
                        if (!requires2FA) ...[
                          SizedBox(
                            width: 400,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(color: Colors.grey),
                                alignLabelWithHint:
                                    true, // Align the hint with the input
                                isDense: true, // Compact internal padding
                                filled: true,
                                fillColor: Colors.grey[200],
                                border:
                                    UnderlineInputBorder(), // Line-style border
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                              ),
                              controller: usernameController,
                              textAlign: TextAlign.center, // Center the text
                            ),
                          ),
                          SizedBox(
                            width: 400,
                            child: TextField(
                              obscureText: true, // Hide the password
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: Colors.grey),
                                alignLabelWithHint: true,
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey[200],
                                border:
                                    UnderlineInputBorder(), // Line-style border
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                              ),
                              controller: passwordController,
                              textAlign: TextAlign.center, // Center the text
                            ),
                          ),
                          SizedBox(height: 30.0),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 100,
                              maxWidth: 300,
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 0.9,
                              child: QFilledButton(
                                onPressed: login,
                                qStyle: QFilledButtonStyle.kConfirm,
                                text: 'Login',
                              ),
                            ),
                          ),
                        ] else ...[
                          const Text(
                            "Make sure to check your spam folder",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          _buildTextField(
                            twoFaController,
                            'Enter 2FA Code',
                            false,
                          ),
                          _build2FAButton(),
                        ],
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Create an Account',
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoginButton() {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 100, maxWidth: 300),
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: QFilledButton(
          onPressed: login,
          qStyle: QFilledButtonStyle.kConfirm,
          text: 'Login',
        ),
      ),
    );
  }

  Widget _build2FAButton() {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 100, maxWidth: 300),
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: QFilledButton(
          onPressed: verify2FA,
          qStyle: QFilledButtonStyle.kConfirm,
          text: 'Verify Code',
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool obscure,
  ) {
    return SizedBox(
      width: 400,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          border: UnderlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
