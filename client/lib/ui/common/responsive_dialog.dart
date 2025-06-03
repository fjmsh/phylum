import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

Future showReponsiveDialog(BuildContext context, String title, WidgetBuilder builder) {
  final account = context.read<PhylumAccount>();
  return showDialog(
    context: context,
    builder: (_) {
      return MultiProvider(
        providers: [
          Provider.value(value: account),
          Provider.value(value: account.actionQueue),
        ],
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
            content: SizedBox(width: 360, child: builder(context)),
            actions: [
              ElevatedButton(onPressed: Navigator.of(context).pop, child: Text('OK')),
            ],
          );
        },
      );
    },
  );
}
