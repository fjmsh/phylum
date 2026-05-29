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
                onPressed: onNextPress,
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
      spacing: 12.0,
      children: [
        // Text(
        //   'Database Setup',
        //   style: Theme.of(context).textTheme.headlineSmall,
        // ),
        // SizedBox(height: 12),
        ListTile(
          title: Text(
            'Database Setup',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          dense: true,
        ),
        TextFormField(
          decoration: const InputDecoration(
              label: Text('Host'), hint: Text('localhost')),
          autofocus: true,
          autocorrect: false,
          keyboardType: TextInputType.url,
          initialValue: config.host,
          onChanged: (value) => context.read<DbController>().host = value,
        ),
        TextFormField(
          decoration:
              const InputDecoration(label: Text('Port'), hint: Text('5432')),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          initialValue: config.port == 0 ? '' : config.port.toString(),
          onChanged: (value) =>
              context.read<DbController>().port = int.tryParse(value) ?? 0,
        ),
        TextFormField(
          decoration: const InputDecoration(
              label: Text('Database Name'), hint: Text('phylum')),
          autocorrect: false,
          initialValue: config.name,
          onChanged: (value) => context.read<DbController>().name = value,
        ),
        TextFormField(
          decoration:
              const InputDecoration(label: Text('User'), hint: Text('phylum')),
          autocorrect: false,
          initialValue: config.user,
          onChanged: (value) => context.read<DbController>().user = value,
        ),
        TextFormField(
          decoration: const InputDecoration(label: Text('Password')),
          autocorrect: false,
          obscureText: true,
          initialValue: config.password,
          onChanged: (value) => context.read<DbController>().password = value,
        ),
        ListTile(
          dense: true,
          title: Text('Connection'),
          subtitle: Text(config.verified == true
              ? 'Connected'
              : config.verified == false
                  ? 'Not Working'
                  : 'Unverified'),
          leading: Icon(config.verified == true
              ? Icons.check_circle
              : config.verified == false
                  ? Icons.cancel
                  : Icons.question_mark),
          trailing: config.verified == null ? Icon(Icons.cable) : null,
          onTap:
              config.verified == null ? () => validateDbConfig(context) : null,
        ),
      ],
    );
  }

  Future<void> validateDbConfig(BuildContext context) async {
    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/db/validate';
    final request = Request('post', builder.build());
    request.body = jsonEncode(context.read<DbConfig>().toMap());

    final responseString =
        await sendRequest(context, 'Checking Database Config', request);
    if (responseString == null || !context.mounted) return;
    final responseMap =
        (jsonDecode(responseString) as Map).cast<String, dynamic>();
    final overrides = (responseMap["overrides"] as List?)?.cast<String>();
    final overrideNote = (overrides?.isNotEmpty ?? false)
        ? "Note: The following settings were overridden by environment variables or command line flags: ${overrides!.join(",")}"
        : "";

    if (responseMap["success"]) {
      context.read<DbController>().verified = true;
    } else {
      context.read<DbController>().verified = false;
      await showAlertDialog(context,
          title: 'Could not connect to DB',
          message: "$overrideNote\n\n${responseMap["error"]}");
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

  set verified(bool value) {
    state = state.withVerified(value);
  }
}

class DbConfig {
  final String host;
  final int port;
  final String name;
  final String user;
  final String password;
  final bool? verified;

  const DbConfig({
    required this.host,
    required this.port,
    required this.name,
    required this.user,
    required this.password,
    required this.verified,
  });

  const DbConfig.defaults()
      : this(
            host: 'localhost',
            port: 5432,
            name: 'phylum',
            user: 'phylum',
            password: 'phylum',
            verified: null);

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
      verified: null,
    );
  }

  DbConfig withVerified(bool verified) {
    return DbConfig(
        host: host,
        port: port,
        name: name,
        user: user,
        password: password,
        verified: verified);
  }

  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'name': name,
        'user': user,
        'password': password,
      };
}
