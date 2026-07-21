import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:uri/uri.dart';

class SetupMailFragment extends StatelessWidget {
  final formKey = GlobalKey<FormState>();
  final String instanceUrl;
  final void Function() onPrevPress;
  final void Function() onNextPress;

  SetupMailFragment({
    super.key,
    required this.instanceUrl,
    required this.onPrevPress,
    required this.onNextPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: buildContents(context)),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: onPrevPress, child: Text('PREV')),
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
    final config = context.watch<MailConfig>();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email', style: Theme.of(context).textTheme.headlineSmall),
          ListTile(
            leading: Icon(Icons.help),
            dense: true,
            title: Text(
              'Used for inviting users, passwordless login, passwordless login, and to send share notifications',
            ),
          ),
          SwitchListTile(
            value: config.enabled,
            onChanged: (value) =>
                context.read<MailController>().enabled = value,
            title: Text('Configure Email?'),
          ),
          if (config.enabled) buildForm(context, config),
        ],
      ),
    );
  }

  Widget buildForm(BuildContext context, MailConfig config) {
    return Form(
      key: formKey,
      child: Column(
        spacing: 18.0,
        children: [
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'SMTP Host '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('localhost'),
              prefixIcon: Icon(Icons.lan),
            ),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            initialValue: config.smtpHost,
            onChanged: (value) =>
                context.read<MailController>().smtpHost = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'SMTP Port '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('587'),
              prefixIcon: Icon(Icons.cable),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            initialValue: config.smtpPort == 0
                ? ''
                : config.smtpPort.toString(),
            onChanged: (value) => context.read<MailController>().smtpPort =
                int.tryParse(value) ?? 0,
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
                    TextSpan(text: 'SMTP Username '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('phylum@example.com'),
              prefixIcon: Icon(Icons.person),
            ),
            autocorrect: false,
            initialValue: config.smtpUsername,
            onChanged: (value) {
              context.read<MailController>().smtpUsername = value;
            },
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: InputDecoration(
              label: Text('SMTP Password'),
              prefixIcon: Icon(Icons.password),
            ),
            autocorrect: false,
            obscureText: true,
            initialValue: config.smtpPassword,
            onChanged: (value) =>
                context.read<MailController>().smtpPassword = value,
          ),
          TextFormField(
            decoration: InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Mail From Name '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('Phylum Drive'),
              prefixIcon: Icon(Icons.contact_mail),
            ),
            autocorrect: false,
            initialValue: config.fromName,
            onChanged: (value) =>
                context.read<MailController>().fromName = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Mail From Email '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('phylum@example.com'),
              prefixIcon: Icon(Icons.alternate_email),
            ),
            autocorrect: false,
            initialValue: config.fromEmail,
            onChanged: (value) =>
                context.read<MailController>().fromEmail = value,
            validator: (value) => value?.isEmpty ?? true
                ? 'Required'
                : EmailValidator.validate(value!)
                ? null
                : 'Invalid Email Address',
          ),
          TextFormField(
            decoration: InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Instance URL '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('https://phylum.example.com'),
              prefixIcon: Icon(Icons.link),
            ),
            autocorrect: false,
            initialValue: config.instanceUrl,
            keyboardType: TextInputType.url,
            onChanged: (value) =>
                context.read<MailController>().instanceUrl = value,
            validator: (value) => value?.isEmpty ?? true
                ? 'Required'
                : Uri.tryParse(value!) == null
                ? 'Invalid URL'
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> validateAndNext(BuildContext context) async {
    if (formKey.currentState?.validate() == false) return;
    final config = context.read<MailConfig>();
    if (!config.enabled) {
      onNextPress();
      return;
    }

    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/mail/test';
    final request = Request('post', builder.build());

    // final sendTo = await showInputDialog(context,
    //     title: 'Sending Test Email',
    //     keyboardType: TextInputType.emailAddress,
    //     labelText: 'Email Address');
    // if (sendTo == null || !context.mounted) {
    //   return;
    // }
    final configMap = config.toMap();
    configMap['send_to'] = config.fromEmail;
    request.body = jsonEncode(configMap);

    final responseString = await sendRequestDialog(
      context,
      request,
      message: 'Validating Email Config',
    );
    if (responseString == null || !context.mounted) return;
    final responseMap = (jsonDecode(responseString) as Map)
        .cast<String, dynamic>();
    final overrides = (responseMap["overrides"] as List?)?.cast<String>();
    final overrideNote = (overrides?.isNotEmpty ?? false)
        ? "Note: The following settings were overridden by environment variables or command line flags: ${overrides!.join(",")}"
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

class MailController extends StateNotifier<MailConfig> {
  MailController(String instanceUrl) : super(MailConfig.defaults(instanceUrl));

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
    state = state.copyWith(
      smtpUsername: value,
      fromEmail: state.smtpUsername == state.fromEmail ? value : null,
    );
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
