import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/theme.dart';
import 'package:phylum/ui/common/dialog_scaffold.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

@JS()
external bool isPrimary();

@JS()
external void setPrimary(JSBoolean value);

Widget buildSingleInstance(Widget child) => SingleInstanceWeb(child: child);

class SingleInstanceWeb extends StatefulWidget {
  final Widget child;

  const SingleInstanceWeb({super.key, required this.child});

  @override
  State<SingleInstanceWeb> createState() => _SingleInstanceWebState();
}

class _SingleInstanceWebState extends State<SingleInstanceWeb> {
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
    final ready = context.select<AccountManagerState<PhylumAccount>, bool>(
      (state) => state.status != .closed,
    );
    return ready
        ? widget.child
        : MaterialApp(
            theme: generateAppTheme(Brightness.light),
            darkTheme: generateAppTheme(Brightness.dark),
            themeMode: context.read<ThemeMode>(),
            builder: (context, child) => PhylumDialogScaffold(
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
              ),
            ),
          );
  }

  void requestHandoff() {
    if (requestId != null) return;
    final r = Random();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

    setState(() {
      requestId = String.fromCharCodes(
        Iterable.generate(12, (_) => chars.codeUnitAt(r.nextInt(chars.length))),
      );
    });

    postMessage('request|$requestId');
    retryRequestTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (retriesLeft-- > 0) {
        if (!requestAccepted) {
          postMessage('request|$requestId');
        }
      } else {
        postMessage('hijack|$requestId');
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

  void postMessage(String message) {
    channel.postMessage(message.toJS);
  }

  void processMessage(web.MessageEvent event) {
    final data = event.data.toString();
    final msg = data.split('|');
    if (msg.length < 2) {
      Log.warn('Unrecognized message: $data');
    }

    if (isPrimary()) {
      if (msg[0] == 'request') {
        final id = msg[1];
        if (accountManager.status == AccountManagerStatus.ready) {
          postMessage('accept|$id');
          accountManager.close().then((v) {
            postMessage('success|$id');
            setPrimary(false.toJS);
          });
        } else {
          postMessage('reject|$id');
        }
      }
      if (msg[0] == 'hijack') {
        accountManager.close();
        setPrimary(false.toJS);
      }
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
