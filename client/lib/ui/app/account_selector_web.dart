import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/login_page.dart';
import 'package:phylum/ui/layout/app_layout.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

@JS()
external bool isPrimary();

@JS()
external void setPrimary(JSBoolean value);

class AccountSelector extends StatefulWidget {
  const AccountSelector({super.key});

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  final channel = web.BroadcastChannel('takover');

  @override
  void initState() {
    super.initState();
    channel.onmessage = processMessage.toJS;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountManagerState<PhylumAccount>>();
    if (state.status != AccountManagerStatus.ready) {
      if (state.status == AccountManagerStatus.closed) {
        return PhylumDialogScaffold(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Phylum is already open in another tab or window'),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text('Use Here'),
              onPressed: () {
                channel.postMessage('close'.toJS);
              },
            ),
          ],
        ));
      }
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

    final account =
        context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.selectedAccount);

    if (account == null) {
      return const LoginPage();
    }
    return AppLayout.create(account);
  }

  void processMessage(web.MessageEvent event) {
    final msg = event.data.toString();
    final accountManager = context.read<AccountManager<PhylumAccount>>();
    if (msg == 'close') {
      if (accountManager.status == AccountManagerStatus.ready) {
        channel.postMessage('closing'.toJS);
        accountManager.close().then((v) {
          channel.postMessage('closed'.toJS);
          setPrimary(false.toJS);
          accountManager.close();
        });
      }
    }
    if (msg == 'closed') {
      setPrimary(true.toJS);
      accountManager.initialize();
    }
  }
}
