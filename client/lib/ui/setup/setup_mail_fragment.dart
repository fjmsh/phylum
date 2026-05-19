import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:uri/uri.dart';

import 'package:phylum/ui/login/base_uri_stub.dart'
    if (dart.library.js_interop) 'package:phylum/ui/login/base_uri_web.dart';

class SetupMailFragment extends StatelessWidget {
  final String instanceUrl;

  const SetupMailFragment({super.key, required this.instanceUrl});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<MailConfig>();
    final enabled = config.enabled;
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
            value: enabled,
            onChanged: (value) => context.read<MailController>().enabled = value ?? false,
            title: Text('Configure Email?'),
            subtitle:
                Text('Email is used for share notifications, password reset, passwordless login, and inviting users'),
          ),
          if (enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Host'), hint: Text('localhost')),
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.url,
              initialValue: config.smtpHost,
              onChanged: (value) => context.read<MailController>().smtpHost = value,
            ),
          if (enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Port'), hint: Text('587')),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              initialValue: config.smtpPort == 0 ? '' : config.smtpPort.toString(),
              onChanged: (value) => context.read<MailController>().smtpPort = int.tryParse(value) ?? 0,
            ),
          if (enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Username'), hint: Text('phylum@example.com')),
              autocorrect: false,
              initialValue: config.smtpUsername,
              onChanged: (value) => context.read<MailController>().smtpUsername = value,
            ),
          if (enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('SMTP Password')),
              autocorrect: false,
              obscureText: true,
              initialValue: config.smtpPassword,
              onChanged: (value) => context.read<MailController>().smtpPassword = value,
            ),
          if (enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('From Name'), hint: Text('Phylum Drive')),
              autocorrect: false,
              initialValue: config.fromName,
              onChanged: (value) => context.read<MailController>().fromName = value,
            ),
          if (enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('From Email'), hint: Text('phylum@example.com')),
              autocorrect: false,
              initialValue: config.fromEmail,
              onChanged: (value) => context.read<MailController>().fromEmail = value,
            ),
          if (enabled)
            TextFormField(
              decoration: const InputDecoration(label: Text('Instance URL'), hint: Text('https://phylum.example.com')),
              autocorrect: false,
              initialValue: config.instanceUrl,
              keyboardType: TextInputType.url,
              onChanged: (value) => context.read<MailController>().instanceUrl = value,
            ),
          if (enabled) ElevatedButton(onPressed: () => validateMailConfig(context), child: Text('Send Test Email'))
        ],
      ),
    );
  }

  Future<void> validateMailConfig(BuildContext context) async {
    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/mail/test';
    final request = Request('post', builder.build());

    final sendTo = await showInputDialog(context,
        title: 'Sending Test Email', keyboardType: TextInputType.emailAddress, labelText: 'Email Address');
    if (sendTo == null || !context.mounted) {
      return;
    }
    final config = context.read<MailConfig>().toMap();
    config['send_to'] = sendTo;
    request.body = jsonEncode(config);
    final responseString = await sendRequest(context, 'Checking Email Config', request);
    if (responseString == null || !context.mounted) return;
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
}

class MailController extends StateNotifier<MailConfig> {
  MailController() : super(MailConfig.defaults());

  set enabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  set smtpHost(String value) {
    state = state.copyWith(smtpHost: value);
  }

  set smtpPort(int value) {
    state = state.copyWith(smtpPort: value);
  }

  set smtpUsername(String value) {
    state = state.copyWith(smtpUsername: value);
  }

  set smtpPassword(String value) {
    state = state.copyWith(smtpPassword: value);
  }

  set fromName(String value) {
    state = state.copyWith(fromName: value);
  }

  set fromEmail(String value) {
    state = state.copyWith(fromEmail: value);
  }

  set instanceUrl(String value) {
    state = state.copyWith(instanceUrl: value);
  }
}

class MailConfig {
  final bool enabled;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String fromName;
  final String fromEmail;
  final String instanceUrl;

  const MailConfig({
    required this.enabled,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.fromName,
    required this.fromEmail,
    required this.instanceUrl,
  });

  MailConfig.defaults()
      : this(
          enabled: false,
          smtpHost: '',
          smtpPort: 587,
          smtpUsername: '',
          smtpPassword: '',
          fromEmail: '',
          fromName: '',
          instanceUrl: webAppBaseUri?.toString() ?? '',
        );

  MailConfig copyWith({
    bool? enabled,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    String? fromName,
    String? fromEmail,
    String? instanceUrl,
  }) {
    return MailConfig(
      enabled: enabled ?? this.enabled,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      fromName: fromName ?? this.fromName,
      fromEmail: fromEmail ?? this.fromEmail,
      instanceUrl: instanceUrl ?? this.instanceUrl,
    );
  }

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
          'instance': instanceUrl,
        }
      : const {};
}
