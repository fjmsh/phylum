import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/setup/setup_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class SetupMailFragment extends SetupFragment<SetupMailFragment> {
  final String instanceUrl;
  final MailConfig config;

  const SetupMailFragment({super.key, required this.instanceUrl, required this.config});

  @override
  SetupFragmentState<SetupMailFragment> createState() => SetupMailFragmentState();
}

class SetupMailFragmentState extends SetupFragmentState<SetupMailFragment> {
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
            'Email',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          CheckboxListTile(
            value: widget.config.enabled,
            onChanged: (value) => setState(() => widget.config.enabled = value ?? false),
            title: Text('Configure Email?'),
            subtitle:
                Text('Email is used for share notifications, password reset, passwordless login, and inviting users'),
          ),
          if (widget.config.enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Host'), hint: Text('localhost')),
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.url,
              initialValue: widget.config.smtpHost,
              onChanged: (value) => widget.config.smtpHost = value,
            ),
          if (widget.config.enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Port'), hint: Text('587')),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              initialValue: widget.config.smtpPort == 0 ? '' : widget.config.smtpPort.toString(),
              onChanged: (value) => widget.config.smtpPort = int.tryParse(value) ?? 0,
            ),
          if (widget.config.enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Username'), hint: Text('phylum@example.com')),
              autocorrect: false,
              initialValue: widget.config.smtpUsername,
              onChanged: (value) => widget.config.smtpUsername = value,
            ),
          if (widget.config.enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Password')),
              autocorrect: false,
              obscureText: true,
              initialValue: widget.config.smtpPassword,
              onChanged: (value) => widget.config.smtpPassword = value,
            ),
          if (widget.config.enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('From Name'), hint: Text('Phylum Drive')),
              autocorrect: false,
              initialValue: widget.config.fromName,
              onChanged: (value) => widget.config.fromName = value,
            ),
          if (widget.config.enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('From Email'), hint: Text('phylum@example.com')),
              autocorrect: false,
              initialValue: widget.config.fromEmail,
              onChanged: (value) => widget.config.fromEmail = value,
            ),
          if (widget.config.enabled) ElevatedButton(onPressed: validateMailConfig, child: Text('Send Test Email'))
        ],
      ),
    );
  }

  Future<void> validateMailConfig() async {
    final builder = UriBuilder.fromUri(Uri.parse(widget.instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/mail/test';
    final request = Request('post', builder.build());

    final sendTo = await showInputDialog(context,
        title: 'Sending Test Email', keyboardType: TextInputType.emailAddress, labelText: 'Email Address');
    if (sendTo == null || !mounted) {
      return;
    }
    final config = widget.config.toMap();
    config['send_to'] = sendTo;
    request.body = jsonEncode(config);
    final responseString = await sendRequest(context, 'Checking Email Config', request);
    if (responseString == null || !mounted) return;
    final responseMap = (jsonDecode(responseString) as Map).cast<String, dynamic>();
    final overrides = (responseMap["overrides"] as List?)?.cast<String>();
    final overrideNote = (overrides?.isNotEmpty ?? false)
        ? "Note: The following settings were overridden by environment variables or command line flags: ${overrides!.join(",")}"
        : "";

    if (responseMap["success"]) {
      await showAlertDialog(context, title: 'Test Email Sent', message: overrideNote.isEmpty ? null : overrideNote);
    } else {
      await showAlertDialog(context,
          title: 'Could not send test email', message: "$overrideNote\n\n${responseMap["error"]}");
    }
  }

  @override
  bool handleNextPress() {
    return true;
  }
}

class MailConfig {
  bool enabled = false;
  String smtpHost = "";
  int smtpPort = 0;
  String smtpUsername = "";
  String smtpPassword = "";
  String fromName = "";
  String fromEmail = "";

  Map<String, dynamic> toMap() => enabled
      ? {
          'smtp': {
            'host': smtpHost,
            'port': smtpPort,
            'username': smtpUsername,
            'password': smtpPassword,
          },
          'from': {
            'name': fromName,
            'email': fromEmail,
          },
        }
      : const {};
}
