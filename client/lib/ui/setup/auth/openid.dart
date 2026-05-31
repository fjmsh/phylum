import 'package:flutter/material.dart';

class OidcDialog extends StatefulWidget {
  final OpenIDConfig config;

  const OidcDialog({super.key, required this.config});

  @override
  State<OidcDialog> createState() => _OidcDialogState();

  static Future<OpenIDConfig?> show(BuildContext context, OpenIDConfig config) {
    return showDialog<OpenIDConfig>(
      context: context,
      builder: (_) => OidcDialog(config: config),
    );
  }
}

class _OidcDialogState extends State<OidcDialog> {
  final formKey = GlobalKey<FormState>();
  late String name;
  late String issuerUrl;
  late String clientId;
  late String clientSecret;
  late bool allowUnverifiedEmails;
  late bool autoCreateUsers;

  @override
  void initState() {
    super.initState();
    name = '';
    issuerUrl = '';
    clientId = '';
    clientSecret = '';
    allowUnverifiedEmails = false;
    autoCreateUsers = false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('OpenID Client Config'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                  label: Text('Name'), hint: Text('Authelia')),
              autofocus: true,
              autocorrect: false,
              textCapitalization: TextCapitalization.words,
              initialValue: name,
              onChanged: (value) => setState(() => name = value),
            ),
            TextFormField(
              decoration: const InputDecoration(
                  label: Text('Issuer URL'),
                  hint: Text('https://auth.example.com')),
              keyboardType: TextInputType.url,
              initialValue: issuerUrl,
              onChanged: (value) => setState(() => issuerUrl = value),
            ),
            TextFormField(
              decoration: const InputDecoration(
                  label: Text('Client ID'), hint: Text('phylum')),
              initialValue: clientId,
              onChanged: (value) => setState(() => clientId = value),
            ),
            TextFormField(
              decoration: const InputDecoration(label: Text('Client Secret')),
              obscureText: true,
              initialValue: clientSecret,
              onChanged: (value) => setState(() => clientSecret = value),
            ),
            SwitchListTile(
              value: allowUnverifiedEmails,
              title: Text('Allow Unverified Emails'),
              subtitle: Text('Use with caution'),
              onChanged: (value) =>
                  setState(() => allowUnverifiedEmails = value),
            ),
            SwitchListTile(
              value: autoCreateUsers,
              title: Text('Auto-create Accounts'),
              subtitle: Text('Only use with trusted private providers'),
              onChanged: (value) => setState(() => autoCreateUsers = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(OpenIDConfig(
            name: name,
            issuerUrl: issuerUrl,
            clientId: clientId,
            clientSecret: clientSecret,
            allowUnverifiedEmails: allowUnverifiedEmails,
            autoCreateUsers: autoCreateUsers,
          )),
          child: Text('OK'),
        ),
      ],
    );
  }
}

class OpenIDConfig {
  final String name;
  final String issuerUrl;
  final String clientId;
  final String clientSecret;
  final bool allowUnverifiedEmails;
  final bool autoCreateUsers;

  const OpenIDConfig({
    required this.name,
    required this.issuerUrl,
    required this.clientId,
    required this.clientSecret,
    required this.allowUnverifiedEmails,
    required this.autoCreateUsers,
  });

  const OpenIDConfig.empty()
      : this(
          name: '',
          issuerUrl: '',
          clientId: '',
          clientSecret: '',
          allowUnverifiedEmails: false,
          autoCreateUsers: false,
        );

  OpenIDConfig copyWith({
    String? id,
    String? name,
    String? issuerUrl,
    String? clientId,
    String? clientSecret,
    bool? allowUnverifiedEmails,
    bool? autoCreateUsers,
  }) =>
      OpenIDConfig(
        name: name ?? this.name,
        issuerUrl: issuerUrl ?? this.issuerUrl,
        clientId: clientId ?? this.clientId,
        clientSecret: clientSecret ?? this.clientSecret,
        allowUnverifiedEmails:
            allowUnverifiedEmails ?? this.allowUnverifiedEmails,
        autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
      );
}
