import 'package:flutter/material.dart';

Future showReponsiveDialog(BuildContext context, String title, WidgetBuilder builder) {
  return showDialog(
    context: context,
    builder: (context) {
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
}
