import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/setup/setup_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class SetupDbFragment extends SetupFragment<SetupDbFragment> {
  final String instanceUrl;
  const SetupDbFragment({super.key, required this.instanceUrl});

  @override
  SetupFragmentState<SetupDbFragment> createState() => SetupDbFragmentState();
}

class SetupDbFragmentState extends SetupFragmentState<SetupDbFragment> {
  final config = DbConfig();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12.0,
        children: [
          Text(
            'Database',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          TextField(
            decoration: const InputDecoration(label: Text('Host'), hint: Text('localhost')),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            onChanged: (value) => config.host = value,
          ),
          TextField(
            decoration: const InputDecoration(label: Text('Port'), hint: Text('5432')),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            onChanged: (value) => config.port = int.tryParse(value),
          ),
          TextField(
            decoration: const InputDecoration(label: Text('Database Name'), hint: Text('phylum')),
            autocorrect: false,
            onChanged: (value) => config.dbName = value,
          ),
          TextField(
            decoration: const InputDecoration(label: Text('User'), hint: Text('phylum')),
            autocorrect: false,
            onChanged: (value) => config.user = value,
          ),
          TextField(
            decoration: const InputDecoration(label: Text('Password')),
            autocorrect: false,
            obscureText: true,
            onChanged: (value) => config.password = value,
          ),
          ElevatedButton(onPressed: validateDbConfig, child: Text('Check Settings'))
        ],
      ),
    );
  }

  Future<void> validateDbConfig() async {
    final builder = UriBuilder.fromUri(Uri.parse(widget.instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/validate/db';
    final request = MultipartRequest('post', builder.build());
    request.fields['host'] = config.host;
    request.fields['port'] = config.port?.toString() ?? '';
    request.fields['db_name'] = config.dbName;
    request.fields['user'] = config.user;
    request.fields['password'] = config.password;

    final responseString = await sendRequest(context, 'Checking Database Config', request);
    if (responseString == null || !mounted) return;
    final responseMap = (jsonDecode(responseString) as Map).cast<String, dynamic>();
    final overrides = (responseMap["overrides"] as List?)?.cast<String>();
    final overrideNote = (overrides?.isNotEmpty ?? false)
        ? "Note: The following settings were overridden by environment variables or command line flags: ${overrides!.join(",")}"
        : "";

    if (responseMap["success"]) {
      await showAlertDialog(context, title: 'Connected to DB', message: overrideNote.isEmpty ? null : overrideNote);
    } else {
      await showAlertDialog(context,
          title: 'Could not connect to DB', message: "$overrideNote\n\n${responseMap["error"]}");
    }
  }

  @override
  bool handleNextPress() {
    return true;
  }
}

class DbConfig {
  String host = "";
  int? port;
  String dbName = "";
  String user = "";
  String password = "";
}
