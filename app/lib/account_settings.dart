import 'package:app/signin.dart';
import 'package:flutter/material.dart';

import 'package:app/api/account.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  bool is2FAEnabled = false;

  @override
  void initState() {
    super.initState();
    fetch2FAStatus(); // fetch status when screen loads
  }

  Future<void> fetch2FAStatus() async {
    String? userEmail = await getCurrentEmail();
    if (userEmail == null || userEmail.isEmpty) {
      print("User email is null or empty");
      return;
    }

    bool status = await check2FAStatus(userEmail); 
    print("Fetched 2FA status: $status");

    if (mounted) {
      setState(() {
        is2FAEnabled = status;
      });
    }
  }

  Future<void> toggle2FA(bool value) async {
    String? userEmail = await getCurrentEmail();
    if (userEmail == null || userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to retrieve email for 2FA.")),
      );
      return;
    }

    bool success =
        value ? await enable2FA(userEmail) : await disable2FA(userEmail);
    if (success) {
      await fetch2FAStatus();
      setState(() {
        is2FAEnabled = value;
        print(is2FAEnabled);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("2FA ${value ? 'enabled' : 'disabled'} successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update 2FA status.")),
      );
    }
  }

  Future<void> handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    final email = await getCurrentEmail();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to retrieve email.")),
      );
      return;
    }

    final success = await deleteAccount(email);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account deleted successfully.")),
      );

      // Replace with your actual login or signup widget if needed
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignIn()),
        (route) => false,
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete account.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Account Settings")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Enable Two-Factor Authentication"),
              Switch(
                value: is2FAEnabled,
                onChanged: toggle2FA,
              ),
              SizedBox(height: 40),
              Divider(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: handleDeleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Delete Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}