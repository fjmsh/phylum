import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class AccountStatePage extends StatelessWidget {
  final Widget child;
  const AccountStatePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountState>();
    if (state == AccountState.ready) return child;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phylum'),
      ),
      body: Center(
        child: Card(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: switch (state) {
                AccountState.closed => buildClosedView(context),
                _ => buildClosingOutView(),
              }
              // state == AccountState.closed ? buildLoggedOutView(context) : buildLoggingOutView(),
              ),
        ),
      ),
    );
  }

  Widget buildClosingOutView() => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircularProgressIndicator(),
          ),
          Text('Logging Out'),
        ],
      );

  Widget buildClosedView(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text('You have been logged out'),
          ),
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
