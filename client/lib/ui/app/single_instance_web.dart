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

@JS()
external void preserveLoader();

@JS()
external JSPromise removeLoader();

final _loaderKey = GlobalKey<_WebLoaderState>();

Widget buildSingleInstance(Widget child) => WebLoader(
  key: _loaderKey,
  child: SingleInstanceWeb(child: child),
);

AccountManager<PhylumAccount> createAccountManager({
  required List<int>? encryptionKey,
  required ActionQueueFactory<PhylumAccount> actionQueueFactory,
}) {
  final accountManager = AccountManager(
    encryptionKey: encryptionKey,
    restoreAccount: (id) => PhylumAccount.restore(id: id),
    actionQueueFactory: actionQueueFactory,
    autoInitialize: isPrimary(),
  );
  WidgetsBinding.instance.deferFirstFrame();
  if (isPrimary()) {
    late void Function() removeListener;
    removeListener = accountManager.addListener((state) async {
      if (state.status != .initializing) {
        Future.microtask(removeListener);
        fadeInApp();
      }
    });
  } else {
    fadeInApp();
  }
  return accountManager;
}

void fadeInApp() async {
  await removeLoader().toDart;
  WidgetsBinding.instance.allowFirstFrame();
  _loaderKey.currentState?.show();
}

class WebLoader extends StatefulWidget {
  final Widget child;
  const WebLoader({super.key, required this.child});

  @override
  State<WebLoader> createState() => _WebLoaderState();
}

class _WebLoaderState extends State<WebLoader> {
  bool ready = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: ready ? 1.0 : 0.0,
      duration: Duration(milliseconds: 400),
      child: widget.child,
    );
  }

  void show() {
    setState(() {
      ready = true;
    });
  }
}

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
    final closed = context.select<AccountManagerState<PhylumAccount>, bool>(
      (state) => state.status == .closed,
    );
    return closed
        ? MaterialApp(
            theme: PhylumTheme.light,
            darkTheme: PhylumTheme.dark,
            themeMode: context.watch<ThemeMode>(),
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
          )
        : widget.child;
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
