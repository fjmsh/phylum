import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class AccountSelector extends StatefulWidget {
  const AccountSelector({super.key});

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  bool errorsDismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountManagerState<PhylumAccount>>();
    if (state.status != AccountManagerStatus.ready) {
      return const PhylumDialogScaffold(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Text('Initializing'),
          ],
        ),
      );
    }
    if (!errorsDismissed && state.invalidAccounts.isNotEmpty) {
      return PhylumDialogScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text('Error', style: TextStyle(fontSize: 20)),
            ),
            Text('Some login sessions not be restored'),
            for (final invalidAccount in state.invalidAccounts.entries)
              ListTile(
                title: Text(invalidAccount.value.serverUrl.host),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => showAlertDialog(
                        context,
                        message: invalidAccount.value.err.toString(),
                      ),
                      icon: Icon(Icons.info_outline),
                    ),
                    IconButton(
                      onPressed: () => context
                          .read<AccountManager<PhylumAccount>>()
                          .removeAccount(invalidAccount.key),
                      icon: Icon(Icons.delete_forever_outlined),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      errorsDismissed = true;
                    });
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return context
            .watch<PhylumRouterDelegate>()
            .currentConfiguration
            ?.buildPage(context) ??
        Container();
  }
}
