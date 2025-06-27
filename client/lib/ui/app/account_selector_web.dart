import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';
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
  final channel = web.BroadcastChannel('handoff');
  late final AccountManager<PhylumAccount> accountManager;
  String? requestId;
  Timer? retryRequestTimer;
  int retriesLeft = 0;
  bool requestAccepted = false;
  bool errorsDismissed = false;

  @override
  void initState() {
    super.initState();
    channel.onmessage = processMessage.toJS;
    accountManager = context.read();
  }

  @override
  void dispose() {
    channel.onmessage = null;
    super.dispose();
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
              onPressed: requestId == null ? requestHandoff : null,
              child: const Text('Use Here'),
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

    if (!errorsDismissed && state.invalidAccounts.isNotEmpty) {
      return PhylumDialogScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text('Error', style: TextStyle(fontSize: 20)),
            ),
            Text('Some accounts could not be restored'),
            for (final invalidAccount in state.invalidAccounts.entries)
              ListTile(
                title: Text(invalidAccount.value.serverUrl.host),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => showAlertDialog(context, message: invalidAccount.value.err.toString()),
                      icon: Icon(Icons.info_outline),
                    ),
                    IconButton(
                      onPressed: () => context.read<AccountManager<PhylumAccount>>().removeAccount(invalidAccount.key),
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
                    child: Text('Skip', style: TextStyle(color: Theme.of(context).colorScheme.error)))
              ],
            )
          ],
        ),
      );
    }

    return context.watch<PhylumRouterDelegate>().currentConfiguration?.buildPage(context) ?? Container();
  }

  void requestHandoff() {
    if (requestId != null) return;
    final r = Random();
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

    setState(() {
      requestId = String.fromCharCodes(Iterable.generate(12, (_) => chars.codeUnitAt(r.nextInt(chars.length))));
    });

    channel.postMessage('request|$requestId'.toJS);
    retryRequestTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (retriesLeft-- > 0) {
        if (!requestAccepted) {
          channel.postMessage('request|$requestId'.toJS);
        }
      } else {
        channel.postMessage('hijack|$requestId'.toJS);
        retryRequestTimer?.cancel();
        retryRequestTimer = null;
        requestId = null;
        setPrimary(true.toJS);
        accountManager.initialize();
      }
    });
    retriesLeft = 5;
    requestAccepted = false;
  }

  void processMessage(web.MessageEvent event) {
    final data = event.data.toString();
    final msg = data.split('|');
    if (msg.length < 2) {
      logger.w('Unrecognized message: $data');
    }

    if (msg[0] == 'request') {
      final id = msg[1];
      if (accountManager.status == AccountManagerStatus.ready) {
        channel.postMessage('accept|$id'.toJS);
        accountManager.close().then((v) {
          channel.postMessage('success|$id'.toJS);
          setPrimary(false.toJS);
        });
      } else {
        channel.postMessage('reject|$id'.toJS);
      }
    }
    if (msg[0] == 'hijack') {
      setPrimary(false.toJS);
    }

    // Process responses, but make sure the id matches
    if (msg[1] != requestId) return;

    if (msg[0] == 'reject') {
      retryRequestTimer?.cancel();
      retryRequestTimer = null;
      requestId = null;
    }
    if (msg[0] == 'accept') {
      // Maybe display a message if this is taking time
      requestAccepted = true;
      retriesLeft += 10;
    }
    if (msg[0] == 'success') {
      retryRequestTimer?.cancel();
      retryRequestTimer = null;
      requestId = null;
      setPrimary(true.toJS);
      accountManager.initialize();
    }
  }
}
