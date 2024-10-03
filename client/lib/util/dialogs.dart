import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          autofocus: true,
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(positiveText),
        ),
      ],
    ),
  );
}

Future<String?> showInputDialog(
  BuildContext context, {
  String? title,
  String? labelText,
  String? hintText,
  String? preset,
  bool barrierDismissable = true,
  TextCapitalization capitalization = TextCapitalization.sentences,
  int minLines = 1,
  int maxLines = 1,
  bool autocorrect = false,
  TextInputType keyboardType = TextInputType.text,
  bool Function(String)? validate,
  List<TextInputFormatter>? formatters,
}) {
  TextEditingController controller = TextEditingController()..text = (preset ?? '');
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissable,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: (title == null) ? null : Text(title),
        content: SizedBox(
          width: 360,
          child: TextField(
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
            ),
            autofocus: true,
            controller: controller,
            textCapitalization: capitalization,
            autocorrect: autocorrect,
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            textInputAction: TextInputAction.go,
            onSubmitted: (value) => (validate == null || validate(value)) ? Navigator.of(context).pop(value) : null,
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
          ElevatedButton(
            onPressed: (validate == null || validate(controller.text))
                ? () {
                    Navigator.of(context).pop(controller.text);
                  }
                : null,
            child: const Text('OK'),
          )
        ],
      );
    }),
  );
}
