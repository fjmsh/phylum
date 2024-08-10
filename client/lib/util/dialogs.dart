import 'package:flutter/material.dart';

Future showProgressDialog(
  BuildContext context, {
  bool barrierDismissible = false,
  String? title,
  String? message,
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: (title == null) ? null : Text(title),
      content: SizedBox(
        width: 360,
        child: Row(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(),
            ),
            if (message != null)
              Text(
                message,
                softWrap: true,
                overflow: TextOverflow.fade,
              ),
          ],
        ),
      ),
    ),
  );
}

Future<bool?> showAlertDialog(
  BuildContext context, {
  bool barrierDismissible = false,
  String? title,
  String? message,
  String? negativeText,
  String positiveText = 'OK',
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: (title == null) ? null : Text(title),
      scrollable: (message?.length ?? 0) > 300,
      content: (message == null)
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                softWrap: true,
              ),
            ),
      actions: <Widget>[
        if (negativeText != null)
          TextButton(
            child: Text(negativeText),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ElevatedButton(
          child: Text(positiveText),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    ),
  );
}
