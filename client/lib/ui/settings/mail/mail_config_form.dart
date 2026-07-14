import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/mail_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:phylum/ui/settings/mail/api/update_request.dart';
import 'package:phylum/ui/settings/mail/api/validate_request.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class MailConfigForm extends StatefulWidget {
  const MailConfigForm({super.key});

  @override
  State<MailConfigForm> createState() => _MailConfigFormState();
}

class _MailConfigFormState extends State<MailConfigForm> {
  final formKey = GlobalKey<FormState>();
  bool _enabled = false;
  bool _smtpUsernameMatchesFromEmail = false;
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  final _fromNameController = TextEditingController();
  final _fromEmailController = TextEditingController();
  final _instanceController = TextEditingController();

  bool requestInFlight = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<RemoteConfigState<MailConfig>>().config!;
    _enabled = config.enabled;
    _smtpHostController.text = config.smtpHost;
    _smtpPortController.text = config.smtpPort == 0
        ? ''
        : config.smtpPort.toString();
    _smtpUsernameController.text = config.smtpUsername;
    _fromNameController.text = config.fromName;
    _fromEmailController.text = config.fromEmail;
    _instanceController.text = config.instanceUrl;
    _smtpUsernameMatchesFromEmail = config.smtpUsername == config.fromEmail;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        spacing: 18.0,
        children: [
          SwitchListTile(
            title: Text('Enable'),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
              if (!value) {
                formKey.currentState?.clearError();
              }
            },
          ),
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
            readOnly: !_enabled,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            controller: _smtpHostController,
            validator: (value) =>
                _enabled && (value?.isEmpty ?? true) ? 'Required' : null,
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
            readOnly: !_enabled,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            controller: _smtpPortController,
            validator: (value) => !_enabled
                ? null
                : value?.isEmpty ?? true
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
            readOnly: !_enabled,
            autocorrect: false,
            onChanged: (value) {
              if (_smtpUsernameMatchesFromEmail) {
                _fromEmailController.text = value;
              } else {
                _smtpUsernameMatchesFromEmail =
                    value == _fromEmailController.text;
              }
            },
            controller: _smtpUsernameController,
            validator: (value) =>
                _enabled && (value?.isEmpty ?? true) ? 'Required' : null,
          ),
          TextFormField(
            decoration: InputDecoration(
              label: Text('SMTP Password'),
              hintText: '<unchanged>',
              prefixIcon: Icon(Icons.password),
            ),
            readOnly: !_enabled,
            autocorrect: false,
            obscureText: true,
            controller: _smtpPasswordController,
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
            readOnly: !_enabled,
            autocorrect: false,
            controller: _fromNameController,
            validator: (value) =>
                _enabled && (value?.isEmpty ?? true) ? 'Required' : null,
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
            readOnly: !_enabled,
            autocorrect: false,
            controller: _fromEmailController,
            onChanged: (value) {
              _smtpUsernameMatchesFromEmail =
                  value == _smtpUsernameController.text;
            },
            validator: (value) => !_enabled
                ? null
                : value?.isEmpty ?? true
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
            readOnly: !_enabled,
            autocorrect: false,
            keyboardType: TextInputType.url,
            controller: _instanceController,
            validator: (value) => !_enabled
                ? null
                : value?.isEmpty ?? true
                ? 'Required'
                : Uri.tryParse(value!) == null
                ? 'Invalid URL'
                : null,
            onFieldSubmitted: (value) => save(context),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 18,
            children: [
              ElevatedButton(
                onPressed: requestInFlight ? null : () => save(context),
                child: Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void validate(BuildContext context) async {
    if (requestInFlight) return;

    setState(() => requestInFlight = true);
    final result = await context.read<PhylumAccount>().apiClient.sendRequest(
      ValidateMailConfigRequest(config: getConfig()),
    );
    if (!context.mounted) return;
    setState(() => requestInFlight = false);

    if (result is ApiSuccessResponse) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mail Config Validated'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      showAlertDialog(
        context,
        title: 'Failed to validate SMTP Config',
        message: result.description,
      );
    }
  }

  void save(BuildContext context) async {
    if (requestInFlight) return;

    setState(() => requestInFlight = true);
    final result = await context.read<PhylumAccount>().apiClient.sendRequest(
      UpdateMailConfigRequest(config: getConfig()),
    );
    if (!context.mounted) return;
    setState(() => requestInFlight = false);

    if (result is ApiSuccessResponse) {
      final account = context.read<PhylumAccount>();
      account.config = account.config.copyWith(mail: _enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mail Config Updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      showAlertDialog(
        context,
        title: 'Failed to update SMTP Config',
        message: result.description,
      );
    }
  }

  MailConfig getConfig() {
    return MailConfig(
      enabled: _enabled,
      smtpHost: _smtpHostController.text,
      smtpPort: int.tryParse(_smtpPortController.text) ?? 0,
      smtpUsername: _smtpUsernameController.text,
      smtpPassword: _smtpPasswordController.text,
      fromName: _fromNameController.text,
      fromEmail: _fromEmailController.text,
      instanceUrl: _instanceController.text,
    );
  }
}
