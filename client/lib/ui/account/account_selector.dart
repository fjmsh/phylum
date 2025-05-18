import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/account/login_page.dart';
import 'package:phylum/ui/app/app.dart';
import 'package:phylum/ui/account/account_selector_app.dart';
import 'package:provider/provider.dart';

class AccountSelector extends StatefulWidget {
  const AccountSelector({super.key});

  @override
  State<AccountSelector> createState() => AccountSelectorState();
}

class AccountSelectorState extends State<AccountSelector> {
  AccountManager<PhylumAccount>? _accountManager;
  bool _errorsDismissed = false;

  @override
  void initState() {
    AccountManager.restore((id) async {
      final account = PhylumAccount.restore(id: id);
      final err = await account.initialized;
      if (err != null) {
        throw err;
      }
      return account;
    }).then((accountManager) {
      setState(() {
        _accountManager = accountManager;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final accountManager = _accountManager;
    if (accountManager == null) {
      return Placeholder();
    }
    return StateNotifierProvider<AccountManager<PhylumAccount>, AccountManagerState<PhylumAccount>>.value(
        value: accountManager,
        builder: (context, child) {
          if (!_errorsDismissed) {}
          final account =
              context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.selectedAccount);

          if (account == null) {
            return const AccountSelectorApp(key: ValueKey('login'), child: LoginPage());
          }

          return PhylumApp.create(account);
        });
  }

  Future<void> closeAccountManager() => _accountManager?.close() ?? SynchronousFuture(null);
}
