import 'package:app/api/account.dart';
import 'package:app/api/types.dart';
import 'package:app/util/loadable.dart';
import 'package:flutter/material.dart';

class Connections extends StatefulWidget {
  const Connections({super.key});

  @override
  ConnectionsState createState() => ConnectionsState();
}

class ConnectionsState extends State<Connections> {
  bool loading = true;
  List<BasicUserInfo> clients = [];

  // Function to delete a client
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
          loading = false;
        });
      } else {
        setState(() {
          this.clients = clients;
          loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Loadable(
      isLoading: loading,
      widgetBuilder: (context) {
        if (clients.isEmpty) {
          return Text('No Connections Found');
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      deleteClient(index);
                    },
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
