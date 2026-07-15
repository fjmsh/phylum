import 'package:flutter/material.dart';
import 'package:phylum/libphylum/config/auth_config.dart';

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
    name = widget.config.name;
    issuerUrl = widget.config.issuerUrl;
    clientId = widget.config.clientId;
    clientSecret = widget.config.clientSecret;
    allowUnverifiedEmails = widget.config.allowUnverifiedEmails;
    autoCreateUsers = widget.config.autoCreateUsers;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('OpenID Client Config'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12.0,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Name '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  hint: Text('Authelia'),
                ),
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.words,
                initialValue: name,
                onChanged: (value) => setState(() => name = value),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Issuer URL '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  hint: Text('https://auth.example.com'),
                ),
                keyboardType: TextInputType.url,
                initialValue: issuerUrl,
                onChanged: (value) => setState(() => issuerUrl = value),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Required'
                    : Uri.tryParse(value!) == null
                    ? 'Invalid URL'
                    : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Client ID '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  hint: Text('phylum'),
                ),
                initialValue: clientId,
                onChanged: (value) => setState(() => clientId = value),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
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
                visualDensity: VisualDensity.compact,
                onChanged: (value) =>
                    setState(() => allowUnverifiedEmails = value),
              ),
              SwitchListTile(
                value: autoCreateUsers,
                title: Text('Auto-create Accounts'),
                subtitle: Text('Only use with trusted private providers'),
                visualDensity: VisualDensity.compact,
                onChanged: (value) => setState(() => autoCreateUsers = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              OpenIDConfig(
                id: widget.config.id,
                name: name,
                issuerUrl: issuerUrl,
                clientId: clientId,
                clientSecret: clientSecret,
                allowUnverifiedEmails: allowUnverifiedEmails,
                autoCreateUsers: autoCreateUsers,
              ),
            );
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
