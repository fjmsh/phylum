import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:provider/provider.dart';

class AccountStatePage extends StatelessWidget {
  final Widget child;
  const AccountStatePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountState>();
    if (state == AccountState.ready) return child;
    if (state == AccountState.closed) {
      return PhylumDialogScaffold(
          child: Column(
        spacing: 16.0,
        children: [
          Text('You have been logged out'),
          ElevatedButton(
            onPressed: () =>
                context.read<AccountManager<PhylumAccount>>().removeAccount(context.read<PhylumAccount>().id),
            child: const Text('OK'),
          ),
        ],
      ));
    }

    return const PhylumDialogScaffold(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16.0,
        children: [
          CircularProgressIndicator(),
          Text('Logging Out'),
        ],
      ),
    );
  }
}
