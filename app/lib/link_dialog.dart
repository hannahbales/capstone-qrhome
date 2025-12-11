import 'package:app/api/account.dart';
import 'package:app/api/types.dart';
import 'package:app/caseworker_home.dart';
import 'package:app/components/buttons.dart';
import 'package:app/components/loading.dart';
import 'package:app/components/text.dart';
import 'package:app/client_home.dart';
import 'package:flutter/material.dart';

class LinkDialog extends StatefulWidget {
  final String link;

  const LinkDialog({super.key, required this.link});

  @override
  // ignore: no_logic_in_create_state
  State<LinkDialog> createState() => _LinkDialogState(linkCode: link);
}

class _LinkDialogState extends State<LinkDialog> {
  final String linkCode;
  BasicUserInfo? meta;

  bool loading = true;

  _LinkDialogState({required this.linkCode});

  @override
  void initState() {
    super.initState();

    Future(() async {
      final meta = await getAccountLinkCodeMeta(linkCode);
      setState(() {
        this.meta = meta;
        loading = false;
      });
    });
  }

  void createLink() async {
    bool res = await linkToClient(linkCode);

    goHome();
    if (mounted) {
      if (res) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully linked with Client'),
            backgroundColor: Colors.green[400],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link with Client'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  void goHome() async {
    var currentAccountType = await getCurrentAccountType();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => currentAccountType == kAccountTypeCaseWorker
              ? CaseworkerHome()
              : ClientHome(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4169E1),
        title: const Text(
          'Link with Client',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: Center(
              child: loading
                  ? qLoadingWidget()
                  : meta == null
                      ? _errorDialog()
                      : _confirmationDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmationDialog() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 40.0,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: <TextSpan>[
              QTextSpan(
                qSize: QTextSize.kMedium,
                text:
                    'Linking with,\n${meta!.firstName} ${meta!.lastName}\n\nAre you sure you want to link?',
              )
            ],
          ),
        ),
        Column(
          spacing: 5.0,
          children: [
            QFilledButton(
              onPressed: () => createLink(),
              qStyle: QFilledButtonStyle.kConfirm,
              text: "Link",
            ),
            QFilledButton(
              onPressed: () => goHome(),
              qStyle: QFilledButtonStyle.kCancel,
              text: "Cancel",
            ),
          ],
        ),
      ],
    );
  }

  Widget _errorDialog() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 40.0,
      children: [
        Text('There has been an error with the link code.'),
        FilledButton(
          onPressed: () => goHome(),
          child: const Text('Home'),
        ),
      ],
    );
  }
}
