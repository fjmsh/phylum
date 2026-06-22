import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/destination_picker/destination_picker.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

class ApiKeyParams {
  final String description;
  final DateTime? expires;
  final List<String> scopes;

  ApiKeyParams({
    required this.description,
    required this.expires,
    required this.scopes,
  });
}

class GenerateApiKeyDialog extends StatefulWidget {
  const GenerateApiKeyDialog({super.key});

  @override
  State<GenerateApiKeyDialog> createState() => _GenerateApiKeyDialogState();

  static Future<ApiKeyParams?> show(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    return showDialog<ApiKeyParams>(
      context: context,
      builder: (context) =>
          Provider.value(value: account, child: GenerateApiKeyDialog()),
    );
  }
}

class _GenerateApiKeyDialogState extends State<GenerateApiKeyDialog> {
  final TextEditingController expiresController = TextEditingController(
    text: 'Never',
  );
  String description = "";
  DateTime? expires;
  final List<String> scopes = [];

  @override
  void dispose() {
    expiresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Generate API Key'),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 18,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                label: Text('Description'),
                hintText: 'Generated via API',
              ),
              onChanged: (value) => description = value,
              autocorrect: true,
              autofocus: true,
            ),
            TextField(
              decoration: InputDecoration(
                label: Text('Expires'),
                suffixIcon: expires == null
                    ? IconButton(
                        icon: Icon(Icons.calendar_month),
                        onPressed: () => pickDate(context),
                      )
                    : IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          expires = null;
                          expiresController.text = 'Never';
                        },
                      ),
              ),
              controller: expiresController,
              readOnly: true,
              onSubmitted: (value) => pickDate(context),
              onTap: () => pickDate(context),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    'Scopes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  trailing: IconButton(
                    onPressed: () => addScope(context),
                    icon: Icon(Icons.add),
                  ),
                ),
                if (scopes.isEmpty)
                  const Text(
                    'None',
                    style: TextStyle(fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                for (final scope in scopes)
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Text(
                          scope,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 24),
                        padding: EdgeInsets.all(3),
                        onPressed: () => setState(
                          () => scopes.removeWhere((e) => e == scope),
                        ),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        ElevatedButton(
          onPressed: scopes.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  ApiKeyParams(
                    description: description,
                    expires: expires,
                    scopes: scopes,
                  ),
                ),
          child: Text('Generate'),
        ),
      ],
    );
  }

  void pickDate(BuildContext context) async {
    final anchor = expires ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 36500)),
      initialDate: anchor,
    );

    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(anchor),
    );

    if (time == null || !context.mounted) return;
    setState(() {
      expires = date.copyWith(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        microsecond: 0,
      );
    });
    expiresController.text = expires!.formatLong();
  }

  void addScope(BuildContext context) async {
    final s = await showOptionsDialog(
      context,
      Scope.values,
      (s) => ListTile(
        visualDensity: VisualDensity.compact,
        dense: true,
        title: Text(s.name),
      ),
      titleText: 'Pick Scope',
    );
    if (s == null) return;
    String scope = s.key;
    String sub = '*';

    final subScopes = s.subScopes;

    if (subScopes != null) {
      if (!context.mounted) return;
      final s = await showOptionsDialog(
        context,
        ['*', ...subScopes],
        (s) => ListTile(
          visualDensity: VisualDensity.compact,
          dense: true,
          title: Text(s),
        ),
      );
      if (s == null) {
        return;
      }
      sub = s;
      if (s != '*') {
        scope = '$scope:$s';
      }
    }
    if (s == Scope.files) {
      if (!context.mounted) return;
      final limit = await showAlertDialog(
        context,
        message:
            'Do you want to limit which files can be accessed using this API Key?',
        positiveText: 'Yes, limit access',
        negativeText: 'No, allow full access',
      );
      if (limit == null || !context.mounted) return;
      if (limit) {
        final id = await DestinationPicker.show(context);
        if (id == null) {
          return;
        }
        scope = '${s.key}:$sub:$id';
      }
    }

    setState(() => scopes.add(scope));
  }
}

enum Scope {
  all('All', '*', null),
  files('Files', 'files', ['read', 'write', 'share']),
  publink('Public Shares', 'publink', ['list', 'create']),
  bookmarks('Bookmarks', 'bookmarks', ['list', 'add', 'remove']),
  keys('API Keys', 'keys', ['list', 'generate', 'revoke']),
  trash('Trash', 'trash', ['list', 'empty', 'restore']);

  final String name;
  final String key;
  final List<String>? subScopes;

  const Scope(this.name, this.key, this.subScopes);
}
