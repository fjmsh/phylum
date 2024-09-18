import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class AppLogout extends StatelessWidget {
  const AppLogout({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phylum'),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: state == AccountState.loggedOut ? buildLoggedOutView(context) : buildLoggingOutView(),
          ),
        ),
      ),
    );
  }

  Widget buildLoggingOutView() => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircularProgressIndicator(),
          ),
          Text('Logging Out'),
        ],
      );

  Widget buildLoggedOutView(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You have been logged out'),
          ElevatedButton(
            onPressed: () {
              final accountId = context.read<PhylumAccount>().id;
              context.read<AccountManager<PhylumAccount>>().removeAccount(accountId);
            },
            child: const Text('OK'),
          ),
        ],
      );
}
