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
  final void Function() onNextPress;
  final formKey = GlobalKey<FormState>();

  SetupDbFragment(
      {super.key, required this.instanceUrl, required this.onNextPress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: buildContents(context))),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: null,
                child: Text('PREV'),
              ),
              TextButton(
                onPressed: () => validateAndNext(context),
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

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 18.0,
        children: [
          Text('Database', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 6),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Host '),
                    TextSpan(text: '*', style: TextStyle(color: Colors.red))
                  ],
                ),
              ),
              hint: Text('localhost'),
              prefixIcon: Icon(Icons.lan),
            ),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            initialValue: config.host,
            onChanged: (value) => context.read<DbController>().host = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Port '),
                    TextSpan(text: '*', style: TextStyle(color: Colors.red))
                  ],
                ),
              ),
              hint: Text('5432'),
              prefixIcon: Icon(Icons.cable),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            initialValue: config.port == 0 ? '' : config.port.toString(),
            onChanged: (value) =>
                context.read<DbController>().port = int.tryParse(value) ?? 0,
            validator: (value) => value?.isEmpty ?? true
                ? 'Required'
                : (int.tryParse(value!) ?? 0) == 0
                    ? 'Invalid Port'
                    : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Datbase Name '),
                    TextSpan(text: '*', style: TextStyle(color: Colors.red))
                  ],
                ),
              ),
              hint: Text('phylum'),
              prefixIcon: Icon(Icons.storage),
            ),
            autocorrect: false,
            initialValue: config.name,
            onChanged: (value) => context.read<DbController>().name = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'User '),
                    TextSpan(text: '*', style: TextStyle(color: Colors.red))
                  ],
                ),
              ),
              hint: Text('phylum'),
              prefixIcon: Icon(Icons.person),
            ),
            autocorrect: false,
            initialValue: config.user,
            onChanged: (value) => context.read<DbController>().user = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
            onFieldSubmitted: (_) => validateAndNext(context),
          ),
        ],
      ),
    );
  }

  void validateAndNext(BuildContext context) async {
    if (formKey.currentState?.validate() == false) return;

    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/db/validate';
    final request = Request('post', builder.build());
    request.body = jsonEncode(context.read<DbConfig>().toMap());

    final responseString = await sendRequestDialog(
      context,
      request,
      message: 'Validating Database Config',
    );
    if (responseString == null || !context.mounted) return;
    final responseMap =
        (jsonDecode(responseString) as Map).cast<String, dynamic>();
    final overrides = (responseMap["overrides"] as List?)?.cast<String>();
    final overrideNote = (overrides?.isNotEmpty ?? false)
        ? "Note: The following settings were overridden by environment variables or command line flags:\n\n${overrides!.join("\n")}"
        : "";

    final error = (responseMap['error'] as Map?)?.cast<String, dynamic>();

    if (error == null) {
      if (overrideNote.isNotEmpty) {
        await showAlertDialog(context, message: overrideNote);
      }
      onNextPress();
    } else {
      String details = error['details'] ?? '';
      if (overrideNote.isNotEmpty) {
        if (details.isNotEmpty) {
          details += '\n\n';
        }
        details += overrideNote;
      }
      showAlertDialog(
        context,
        title: error['msg'],
        message: details.isEmpty ? null : details,
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
