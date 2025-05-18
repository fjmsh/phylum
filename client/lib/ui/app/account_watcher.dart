import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/login_page.dart';
import 'package:phylum/ui/layout/app_layout.dart';
import 'package:provider/provider.dart';

class AccountWatcher extends StatelessWidget {
  const AccountWatcher({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountManagerState<PhylumAccount>>();
    if (state.status != AccountManagerStatus.ready) {
      return Scaffold(
          body: Center(
        child: Card(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Image(
                          image: AssetImage('assets/images/logo.png'),
                          height: 36,
                          width: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Text('PHYLUM', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  SizedBox(height: 12),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 12),
                      Text('Loading'),
                    ],
                  ),
                ],
              )),
        ),
      ));
    }
    final account =
        context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.selectedAccount);

    if (account == null) {
      return const LoginPage();
    }
    return AppLayout.create(account);
  }
}
