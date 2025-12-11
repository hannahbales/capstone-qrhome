import 'package:app/api/account.dart';
import 'package:app/info.dart';
import 'package:app/signin.dart';
import 'package:app/api/types.dart';
import 'package:app/familyform.dart';
import 'package:app/files.dart';
import 'package:app/util/loadable.dart';
import 'package:flutter/material.dart';
import 'form.dart';

class CaseworkerHome extends StatefulWidget {
  const CaseworkerHome({super.key});

  @override
  CaseworkerHomeState createState() => CaseworkerHomeState();
}

class CaseworkerHomeState extends State<CaseworkerHome> {
  bool isLoading = true;
  List<BasicUserInfo> clients = [];

  void deleteClient(int index) async {
    final res = await unlinkWithUser(clients[index].email);

    if (!res && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unlink with User'),
          backgroundColor: Colors.red[400],
        ),
      );
    } else {
      setState(() {
        clients.removeAt(index);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    Future(() async {
      final List<BasicUserInfo>? clients = await getLinks();
      if (clients == null) {
        print('No clients found');

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          this.clients = clients;
          isLoading = false;
        });
      }
    });
  }

  Widget clientsView() {
    if (clients.isEmpty) {
      return const Text(
        "No clients found",
        textAlign: TextAlign.center,
      );
    } else {
      return ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                  '${clients[index].firstName} ${clients[index].lastName}'),
              subtitle: Text(clients[index].email),
              trailing: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: 'View Application',
                      onPressed: () => showApplicationForm(context, true,
                          applicantName:
                              '${clients[index].firstName} ${clients[index].lastName}',
                          clientEmail: clients[index].email),
                    ),
                    IconButton(
                      icon: const Icon(Icons.group),
                      tooltip: 'View Family',
                      onPressed: () => showFamilyBottomSheet(
                        context,
                        true,
                        clients[index].email,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder),
                      tooltip: 'View Files',
                      onPressed: () => showFilesBottomSheet(
                        context,
                        true,
                        clients[index].email,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Client',
                      onPressed: () {
                        deleteClient(index);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [ShowInfoButton()]),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Client Connections',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Table
            Expanded(
              child: Loadable(
                isLoading: isLoading,
                widgetBuilder: (context) => clientsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
