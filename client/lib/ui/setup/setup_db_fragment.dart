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
  final DbConfig config;
  const SetupDbFragment({super.key, required this.instanceUrl, required this.config});

  @override
  SetupFragmentState<SetupDbFragment> createState() => SetupDbFragmentState();
}

class SetupDbFragmentState extends SetupFragmentState<SetupDbFragment> {
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
          TextFormField(
            decoration: const InputDecoration(label: Text('Host'), hint: Text('localhost')),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            initialValue: widget.config.host,
            onChanged: (value) => widget.config.host = value,
          ),
          TextFormField(
            decoration: const InputDecoration(label: Text('Port'), hint: Text('5432')),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            initialValue: widget.config.port == 0 ? '' : widget.config.port.toString(),
            onChanged: (value) => widget.config.port = int.tryParse(value) ?? 0,
          ),
          TextFormField(
            decoration: const InputDecoration(label: Text('Database Name'), hint: Text('phylum')),
            autocorrect: false,
            initialValue: widget.config.name,
            onChanged: (value) => widget.config.name = value,
          ),
          TextFormField(
            decoration: const InputDecoration(label: Text('User'), hint: Text('phylum')),
            autocorrect: false,
            initialValue: widget.config.user,
            onChanged: (value) => widget.config.user = value,
          ),
          TextFormField(
            decoration: const InputDecoration(label: Text('Password')),
            autocorrect: false,
            obscureText: true,
            initialValue: widget.config.password,
            onChanged: (value) => widget.config.password = value,
          ),
          ElevatedButton(onPressed: validateDbConfig, child: Text('Check Settings'))
        ],
      ),
    );
  }

  Future<void> validateDbConfig() async {
    final builder = UriBuilder.fromUri(Uri.parse(widget.instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/db/validate';
    final request = Request('post', builder.build());
    request.body = jsonEncode(widget.config.toMap());

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
  int port = 0;
  String name = "";
  String user = "";
  String password = "";

  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'name': name,
        'user': user,
        'password': password,
      };
}
