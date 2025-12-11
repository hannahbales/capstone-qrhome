import 'dart:io';

import 'package:app/account_settings.dart';
import 'package:app/api/account.dart';
import 'package:app/info.dart';
import 'package:app/linking/connections.dart';
import 'package:app/signin.dart';
import 'package:app/familyform.dart';
import 'package:app/files.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'form.dart';

const double qrCodeRadius = 15.0;

BoxShadow qrShadow() {
  return BoxShadow(
    spreadRadius: -5.0,
    blurRadius: 10.0,
    offset: Offset(0.0, 2.0),
    color: Colors.grey[600]!,
  );
}

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  String? url;

  @override
  void initState() {
    super.initState();

    Future(() async {
      final url = await getLinkUrl();
      setState(() {
        this.url = url;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showSettingsForm(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'QR Home',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              key: Key('form_button'),
              leading: Icon(Icons.assignment),
              title: Text('My Application'),
              onTap: () {
                Navigator.pop(context);
                showApplicationForm(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.family_restroom),
              title: Text('My Family'),
              onTap: () {
                Navigator.pop(context);
                showFamilyBottomSheet(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.file_upload),
              title: Text('My Uploads'),
              onTap: () {
                Navigator.pop(context);
                showUploads(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.people_outline),
              title: Text('My Connections'),
              onTap: () {
                Navigator.pop(context);
                showConnections(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('App Info'),
              onTap: () {
                Navigator.pop(context);
                showInfo(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                logout(); //For clearing preferences/cookies, won't log out the user without this
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignIn()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Flexible(
              flex: 1,
              child: SizedBox(
                width: 450,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: url == null
                        ? LoadingAnimationWidget.waveDots(
                            color: Colors.blue,
                            size: 100.0,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              boxShadow: [qrShadow()],
                              borderRadius: BorderRadius.circular(
                                qrCodeRadius,
                              ),
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.all(0.0),
                            child: QrImageView(
                              data: url!,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              padding: EdgeInsets.all(qrCodeRadius),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/**
 * Navigation functions
 */

// Reusable function to show a bottom sheet with a title and content widget
void showBottomSheet(
  BuildContext context, {
  required String title,
  required Widget contentWidget,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(child: contentWidget),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showSettingsForm(BuildContext context) {
  showBottomSheet(
    context,
    title: 'Account Settings',
    contentWidget: AccountSettings(),
  );
}

void showApplicationForm(BuildContext context) {
  showBottomSheet(
    context,
    title: 'Application Form',
    contentWidget: ApplicationForm(isReadOnly: false),
  );
}

void showFamilyBottomSheet(BuildContext context) {
  showBottomSheet(
    context,
    title: 'Edit Family',
    contentWidget: FamilyMembersForm(),
  );
}

void showFilesForm(BuildContext context) {
  showBottomSheet(context, title: 'Files', contentWidget: Files());
}

void showConnections(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close (X) button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Connections",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Form content scrolls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: Connections(),
            ),
          ),
        ],
      ),
    ),
  );
}

void showUploads(BuildContext context) {
  showBottomSheet(
    context,
    title: 'Files',
    contentWidget: Files(),
  );
}
