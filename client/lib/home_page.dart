import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final id = account.userHome;

    account.datastore.db.managers.resources.get().then((c) {
      for (final i in c) {
        print(i);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phylum'),
      ),
      body: Center(
        child: StreamBuilder(
            stream: account.datastore.db.managers.resources.filter((f) => f.parent.id.equals(id)).watch(),
            builder: (context, snapshot) {
              return Column(
                children: [
                  if (snapshot.hasData)
                    for (final i in snapshot.data!) ListTile(title: Text(i.name)),
                  ElevatedButton(
                      onPressed: () {
                        account.api.sendRequest(ResourceDetailRequest(account.userHome));
                      },
                      child: const Text('Get Details'))
                ],
              );
            }),
      ),
    );
  }
}
