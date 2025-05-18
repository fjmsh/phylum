import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

Future showReponsiveDialog(BuildContext context, String title, WidgetBuilder builder) {
  return showDialog(
    context: context,
    builder: (_) {
      return StateNotifierProvider<PhylumAccount, AccountState>.value(
        value: context.read(),
        builder: (_, __) {
          final width = MediaQuery.sizeOf(context).width;
          if (width <= 600) {
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: SingleChildScrollView(child: builder(context)),
            );
          }
          return AlertDialog(
            title: Text(title),
            scrollable: true,
            content: SizedBox(width: 300, child: builder(context)),
            actions: [
              ElevatedButton(onPressed: Navigator.of(context).pop, child: Text('OK')),
            ],
          );
        },
      );
    },
  );
}
