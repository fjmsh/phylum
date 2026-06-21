import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

final TextInputFormatter validIdFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-Z0-9_\-]'),
);

class PublinkInfo with ChangeNotifier {
  String _id = '';
  String get id => _id.trim();
  set id(String value) {
    _id = value;
    notifyListeners();
  }

  String _password = '';
  String get password => _password;
  set password(String value) {
    _password = value;
    notifyListeners();
  }

  DateTime? _expiration;
  DateTime? get expiration => _expiration;
  set expiration(DateTime? value) {
    _expiration = value;
    notifyListeners();
  }

  int? _accessLimit;
  int get accessLimit => _accessLimit ?? 0;
  set accessLimit(int? value) {
    _accessLimit = value;
    notifyListeners();
  }

  PublinkInfo();
}

class CreatePublinkView extends StatefulWidget {
  final String resourceId;

  CreatePublinkView._({required this.resourceId})
    : super(key: ValueKey(resourceId));

  @override
  State<CreatePublinkView> createState() => _CreatePublinkViewState();

  static Future<PublinkInfo?> show(BuildContext context, String resourceId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) => PublinkInfo(),
          builder: (context, child) {
            return AlertDialog(
              title: const Text('Create Public Share'),
              scrollable: true,
              content: SizedBox(
                width: 300,
                child: CreatePublinkView._(resourceId: resourceId),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: Navigator.of(context).pop,
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      context.select<PublinkInfo, bool>(
                        (info) => info.id.isNotEmpty,
                      )
                      ? () => Navigator.of(
                          context,
                        ).pop(context.read<PublinkInfo>())
                      : null,
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CreatePublinkViewState extends State<CreatePublinkView> {
  final expiresController = TextEditingController();
  bool passwordVisible = false;

  @override
  void dispose() {
    expiresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.public),
          title: TextField(
            decoration: InputDecoration(label: Text('ID')),
            inputFormatters: [validIdFormatter],
            enableSuggestions: false,
            autocorrect: false,
            autofocus: true,
            onChanged: (value) => context.read<PublinkInfo>().id = value,
          ),
        ),
        ListTile(
          leading: Icon(Icons.password),
          title: TextField(
            decoration: InputDecoration(
              label: Text('Password'),
              suffixIcon: passwordVisible
                  ? IconButton(
                      icon: Icon(Icons.visibility_off_outlined),
                      onPressed: () => setState(() => passwordVisible = false),
                    )
                  : IconButton(
                      icon: Icon(Icons.visibility_outlined),
                      onPressed: () => setState(() => passwordVisible = true),
                    ),
            ),
            obscureText: !passwordVisible,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: (value) => context.read<PublinkInfo>().password = value,
          ),
        ),
        ListTile(
          leading: Icon(Icons.access_time),
          title: Builder(
            builder: (context) {
              final expiration = context.select<PublinkInfo, DateTime?>(
                (info) => info.expiration,
              );
              expiresController.text = expiration == null
                  ? 'Never'
                  : expiration.formatLong();
              return TextField(
                decoration: InputDecoration(
                  label: Text('Expires'),
                  suffixIcon: expiration == null
                      ? null
                      : IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () =>
                              context.read<PublinkInfo>().expiration = null,
                        ),
                ),
                readOnly: true,
                controller: expiresController,
                onTap: () async {
                  final info = context.read<PublinkInfo>();
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 3650)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(now),
                  );
                  if (time == null) return;
                  info.expiration = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                },
              );
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.numbers),
          title: TextField(
            decoration: InputDecoration(label: Text('Access Limit')),
            enableSuggestions: false,
            autocorrect: false,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) =>
                context.read<PublinkInfo>().accessLimit = int.tryParse(value),
          ),
        ),
      ],
    );
  }
}
