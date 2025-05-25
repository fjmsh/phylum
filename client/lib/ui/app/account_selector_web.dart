import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/login/login_page.dart';
import 'package:phylum/ui/layout/app_layout.dart';
import 'package:phylum/ui/login/reset_password_page.dart';
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
      return kDebugMode ? const LoginPage() : LoginPage(fixedInstanceUrl: Uri());
    }
    return AppLayout.create(account);
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
