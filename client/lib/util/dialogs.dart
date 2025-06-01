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

Future showProgresIndicatorDialog(
  BuildContext context, {
  required Stream<double?> progress,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (message != null)
              Text(
                message,
                softWrap: true,
                overflow: TextOverflow.fade,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StreamBuilder(
                  stream: progress,
                  initialData: null,
                  builder: (context, snapshot) => LinearProgressIndicator(value: snapshot.data)),
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
  Widget? contents,
  String? negativeText,
  String positiveText = 'OK',
}) {
  assert(message == null || contents == null);
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: (title == null) ? null : Text(title),
      scrollable: (message?.length ?? 0) > 300,
      content: (contents == null && message == null)
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: contents ??
                  Text(
                    message!,
                    softWrap: true,
                  ),
            ),
      actions: <Widget>[
        if (negativeText != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(negativeText),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ElevatedButton(
          autofocus: true,
          child: Text(positiveText),
          onPressed: () => Navigator.of(context).pop(true),
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
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          ElevatedButton(
            onPressed: (validate == null || validate(controller.text))
                ? () => Navigator.of(context).pop(controller.text)
                : null,
            child: const Text('OK'),
          )
        ],
      );
    }),
  );
}

Future<T?> showOptionsDialogBuilder<T>(
  BuildContext context,
  List<T> options,
  Widget Function(T) buildItem, {
  String? titleText,
  List<T> Function(List<T>, String)? filterList,
  bool Function(T, String)? filterTerm,
  Widget Function(BuildContext context)? buildLastItem,
}) async {
  var results = options;
  filterList ??= filterTerm == null
      ? null
      : (List<T> options, String query) {
          final q = query.toLowerCase();
          return options.where((element) => filterTerm(element, q)).toList();
        };
  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: (titleText == null) ? null : Text(titleText),
          content: SizedBox(
            width: 360,
            height: 600,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: (results.isEmpty ? 1 : results.length) +
                    (filterList == null ? 0 : 1) +
                    (buildLastItem == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (filterList != null) {
                    index--;
                  }
                  if (index < 0) {
                    return TextField(
                        decoration: const InputDecoration(hintText: 'Type to filter...'),
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {
                            results = filterList!(options, value);
                          });
                        });
                  }
                  if (index >= results.length) {
                    return buildLastItem?.call(context) ?? const ListTile(title: Text('No Matches'));
                  }
                  return InkWell(
                    child: buildItem(results[index]),
                    onTap: () {
                      Navigator.of(context).pop(results[index]);
                    },
                  );
                }),
          )),
    ),
  );
}
