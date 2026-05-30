import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:uri/uri.dart';

class SetupDbFragment extends StatelessWidget {
  final String instanceUrl;
  final void Function()? onPrevPress;
  final void Function() onNextPress;

  const SetupDbFragment(
      {super.key,
      required this.instanceUrl,
      required this.onPrevPress,
      required this.onNextPress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: buildContents(context)),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onPrevPress,
                child: Text('PREV'),
              ),
              TextButton(
                onPressed: () => validateDbConfig(context),
                child: Text('NEXT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildContents(BuildContext context) {
    final config = context.watch<DbConfig>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12.0,
      children: [
        Text(
          'Database Configuration',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            label: Text('Host'),
            hint: Text('localhost'),
            prefixIcon: Icon(Icons.lan),
          ),
          autofocus: true,
          autocorrect: false,
          keyboardType: TextInputType.url,
          initialValue: config.host,
          onChanged: (value) => context.read<DbController>().host = value,
        ),
        TextFormField(
          decoration: const InputDecoration(
            label: Text('Port'),
            hint: Text('5432'),
            prefixIcon: Icon(Icons.cable),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          initialValue: config.port == 0 ? '' : config.port.toString(),
          onChanged: (value) =>
              context.read<DbController>().port = int.tryParse(value) ?? 0,
        ),
        TextFormField(
          decoration: const InputDecoration(
            label: Text('Database Name'),
            hint: Text('phylum'),
            prefixIcon: Icon(Icons.storage),
          ),
          autocorrect: false,
          initialValue: config.name,
          onChanged: (value) => context.read<DbController>().name = value,
        ),
        TextFormField(
          decoration: const InputDecoration(
            label: Text('User'),
            hint: Text('phylum'),
            prefixIcon: Icon(Icons.person),
          ),
          autocorrect: false,
          initialValue: config.user,
          onChanged: (value) => context.read<DbController>().user = value,
        ),
        TextFormField(
          decoration: const InputDecoration(
            label: Text('Password'),
            prefixIcon: Icon(Icons.password),
          ),
          autocorrect: false,
          obscureText: true,
          initialValue: config.password,
          onChanged: (value) => context.read<DbController>().password = value,
          onFieldSubmitted: (_) => validateDbConfig(context),
        ),
      ],
    );
  }

  void validateDbConfig(BuildContext context) async {
    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/db/validate';
    final request = Request('post', builder.build());
    request.body = jsonEncode(context.read<DbConfig>().toMap());

    final responseString =
        await sendRequest(context, 'Checking Database Config', request);
    if (!context.mounted) return;
    if (responseString == null) {
      showAlertDialog(context, title: 'Unable to reach server');
      return;
    }
    final responseMap =
        (jsonDecode(responseString) as Map).cast<String, dynamic>();
    final overrides = (responseMap["overrides"] as List?)?.cast<String>();
    final overrideNote = (overrides?.isNotEmpty ?? false)
        ? "Note: The following settings were overridden by environment variables or command line flags:\n\n${overrides!.join("\n")}"
        : "";

    if (responseMap["success"]) {
      if (overrideNote.isNotEmpty) {
        await showAlertDialog(context, message: overrideNote);
      }
      onNextPress();
    } else {
      String message = responseMap['details'] ?? '';
      if (overrideNote.isNotEmpty) {
        if (message.isNotEmpty) {
          message += '\n\n';
        }
        message += overrideNote;
      }
      showAlertDialog(
        context,
        title: responseMap['error'],
        message: message.isEmpty ? null : message,
      );
    }
  }
}

class DbController extends StateNotifier<DbConfig> {
  DbController() : super(DbConfig.defaults());

  set host(String value) {
    state = state.copyWith(host: value);
  }

  set port(int value) {
    state = state.copyWith(port: value);
  }

  set name(String value) {
    state = state.copyWith(name: value);
  }

  set user(String value) {
    state = state.copyWith(user: value);
  }

  set password(String value) {
    state = state.copyWith(password: value);
  }
}

class DbConfig {
  final String host;
  final int port;
  final String name;
  final String user;
  final String password;

  const DbConfig({
    required this.host,
    required this.port,
    required this.name,
    required this.user,
    required this.password,
  });

  const DbConfig.defaults()
      : this(
          host: 'localhost',
          port: 5432,
          name: 'phylum',
          user: 'phylum',
          password: 'phylum',
        );

  DbConfig copyWith({
    String? host,
    int? port,
    String? name,
    String? user,
    String? password,
  }) {
    return DbConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      name: name ?? this.name,
      user: user ?? this.user,
      password: password ?? this.password,
    );
  }

  DbConfig withError(String error) {
    return DbConfig(
      host: host,
      port: port,
      name: name,
      user: user,
      password: password,
    );
  }

  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'name': name,
        'user': user,
        'password': password,
      };
}
