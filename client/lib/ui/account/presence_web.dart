import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:phylum/ui/account/account_selector.dart';
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
  final key = GlobalKey<AccountSelectorState>();
  final channel = web.BroadcastChannel('takover');
  bool primary = isPrimary();

  @override
  void initState() {
    super.initState();
    channel.onmessage = processMessage.toJS;
  }

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return AccountSelector(key: key);
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
      final state = key.currentState;
      if (state != null) {
        channel.postMessage('closing'.toJS);
        state.closeAccountManager().then((v) {
          channel.postMessage('closed'.toJS);
          setPrimary(false.toJS);
          setState(() {
            primary = false;
          });
        });
      }
    }
    if (msg == 'closed') {
      setPrimary(true.toJS);
      setState(() {
        primary = true;
      });
    }
  }
}
