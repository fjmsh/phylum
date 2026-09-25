import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:provider/provider.dart';

class ExistingLoginScreen extends StatelessWidget {
  final Map<String, PhylumAccount> _accounts;
  const ExistingLoginScreen({super.key, required this._accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        Text('You are already logged in'),
        ..._accounts.values.map(
          (account) => ListTile(
            title: Text('${account.user.name} (${account.user.email})'),
            subtitle: Text(account.apiClient.serverUrl.toString()),
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<PhylumRouterDelegate>().go(HomeRoute());
          },
          child: Text('Go Back'),
        ),
        TextButton(
          onPressed: () {
            final accountManager = context
                .read<AccountManager<PhylumAccount>>();
            for (final id in _accounts.keys) {
              accountManager.removeAccount(id);
            }
          },
          child: Text(
            'Log Out',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
