import 'package:flutter/widgets.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

Widget buildSingleInstance(Widget child) => child;

AccountManager<PhylumAccount> createAccountManager(
  ActionQueueFactory<PhylumAccount> actionQueueFactory,
) {
  return AccountManager(
    restoreAccount: (id) => PhylumAccount.restore(id: id),
    actionQueueFactory: actionQueueFactory,
  );
}
