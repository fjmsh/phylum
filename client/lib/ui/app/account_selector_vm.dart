import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/login_page.dart';
import 'package:phylum/ui/layout/app_layout.dart';
import 'package:phylum/ui/login/reset_password_page.dart';
import 'package:provider/provider.dart';

bool isPrimary() => true;

class AccountSelector extends StatelessWidget {
  const AccountSelector({super.key});

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
      ));
    }

    final route = context.select<PhylumRouterDelegate, ResetPasswordRoute?>((state) =>
        state.currentConfiguration is ResetPasswordRoute ? state.currentConfiguration as ResetPasswordRoute : null);
    if (route != null) {
      return ResetPasswordPage(
        instanceUrl: route.instanceUri,
        email: route.email,
        token: route.token,
      );
    }

    final account =
        context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.selectedAccount);

    if (account == null) {
      return const LoginPage();
    }
    return AppLayout.create(account);
  }
}
