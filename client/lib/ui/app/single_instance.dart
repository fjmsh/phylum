import 'package:flutter/widgets.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

Widget buildSingleInstance(Widget child) => child;

AccountManager<PhylumAccount> createAccountManager({
  required List<int>? encryptionKey,
  required ActionQueueFactory<PhylumAccount> actionQueueFactory,
}) {
  return AccountManager(
    encryptionKey: encryptionKey,
    restoreAccount: (id) => PhylumAccount.restore(id: id),
    actionQueueFactory: actionQueueFactory,
  );
}
