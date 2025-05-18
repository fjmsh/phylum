import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:web/web.dart' as web;

@JS()
external bool isPrimary();

@JS()
external void setPrimary(JSBoolean value);

Widget buildApp() => const PrimaryNegotiator();

class PrimaryNegotiator extends StatefulWidget {
  const PrimaryNegotiator({super.key});

  @override
  State<PrimaryNegotiator> createState() => _PrimaryNegotiatorState();
}

class _PrimaryNegotiatorState extends State<PrimaryNegotiator> {
  final routerDelegate = PhylumRouterDelegate();
  AccountManager<PhylumAccount>? accountManager;
  final channel = web.BroadcastChannel('takover');

  @override
  void initState() {
    super.initState();
    channel.onmessage = processMessage.toJS;
    if (isPrimary()) {
      accountManager = createAccountManager();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (accountManager != null) {
      return PhylumApp(
        accountManager: accountManager!,
        routerDelegate: routerDelegate,
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Phylum is running in another tab or window.'),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        child: Text('Use here'),
                        onPressed: () {
                          channel.postMessage('close'.toJS);
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void processMessage(web.MessageEvent event) {
    final msg = event.data.toString();
    if (msg == 'close') {
      final accountManager = this.accountManager;
      if (accountManager != null) {
        channel.postMessage('closing'.toJS);
        accountManager.close().then((v) {
          channel.postMessage('closed'.toJS);
          setPrimary(false.toJS);
          setState(() {
            this.accountManager = null;
          });
        });
      }
    }
    if (msg == 'closed') {
      setPrimary(true.toJS);
      setState(() {
        accountManager = createAccountManager();
      });
    }
  }
}
