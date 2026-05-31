import 'package:flutter/material.dart';
import 'package:phylum/ui/setup/setup_auth_fragment.dart';

class LdapConfigDialog extends StatefulWidget {
  final LdapConfig config;

  const LdapConfigDialog({super.key, required this.config});

  @override
  State<LdapConfigDialog> createState() => _LdapConfigDialogState();

  static Future<LdapConfig?> show(BuildContext context, LdapConfig config) {
    return showDialog<LdapConfig>(
      context: context,
      builder: (_) => LdapConfigDialog(config: config),
    );
  }
}

class _LdapConfigDialogState extends State<LdapConfigDialog> {
  final formKey = GlobalKey<FormState>();
  late String url;
  late bool starttls;
  late bool autoCreateUsers;
  late bool useFilter;
  late String dnTemplate;
  late String bindDn;
  late String bindPassword;
  late String baseDn;
  late String filterTemplate;

  @override
  void initState() {
    super.initState();
    url = widget.config.url;
    starttls = widget.config.starttls;
    autoCreateUsers = widget.config.useFilter;
    useFilter = widget.config.useFilter;
    dnTemplate = widget.config.dnTemplate;
    bindDn = widget.config.bindDn;
    bindPassword = widget.config.bindDn;
    baseDn = widget.config.baseDn;
    filterTemplate = widget.config.filterTemplate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('LDAP Configuration'),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Server URL '),
                        TextSpan(text: '*', style: TextStyle(color: Colors.red))
                      ],
                    ),
                  ),
                  prefixIcon: Icon(Icons.lan),
                  hint: Text('ldap://ldap.example.com:389'),
                ),
                keyboardType: TextInputType.url,
                initialValue: url,
                onChanged: (value) => setState(() => url = value),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Required'
                    : Uri.tryParse(value!) == null
                        ? 'Invalid URL'
                        : null,
              ),
              SwitchListTile(
                value: starttls,
                title: const Text('Use STARTTLS'),
                secondary: Icon(Icons.lock),
                onChanged: (value) => setState(() => starttls = value),
              ),
              SwitchListTile(
                value: useFilter,
                title: const Text('Search for DN'),
                subtitle: Text('For converting email to DN'),
                onChanged: (value) => setState(() => useFilter = value),
              ),
              if (!useFilter)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      label: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'DN Template '),
                            TextSpan(
                                text: '*', style: TextStyle(color: Colors.red))
                          ],
                        ),
                      ),
                      hint: Text('uid={email},ou=people,dc=example,dc=com'),
                    ),
                    initialValue: dnTemplate,
                    key: ValueKey('dn_template'),
                    onChanged: (value) => setState(() => dnTemplate = value),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    spacing: 12.0,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Bind DN'),
                                  TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Colors.red))
                                ],
                              ),
                            ),
                            hint:
                                Text('uid=phylum,ou=people,dc=example,dc=com')),
                        initialValue: bindDn,
                        key: ValueKey('bind_dn'),
                        onChanged: (value) => setState(() => bindDn = value),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(label: Text('Bind Password')),
                        initialValue: bindPassword,
                        obscureText: true,
                        key: ValueKey('bind_password'),
                        onChanged: (value) =>
                            setState(() => bindPassword = value),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          label: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Base DN'),
                                TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red))
                              ],
                            ),
                          ),
                          hint: Text('dc=example,dc=com'),
                        ),
                        initialValue: bindDn,
                        key: ValueKey('base_dn'),
                        onChanged: (value) => setState(() => baseDn = value),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          label: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Filter Template'),
                                TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red))
                              ],
                            ),
                          ),
                          hint: Text('(mail={email})'),
                        ),
                        initialValue: filterTemplate,
                        key: ValueKey('filter_template'),
                        onChanged: (value) =>
                            setState(() => filterTemplate = value),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              SwitchListTile(
                value: autoCreateUsers,
                title: Text('Auto-create Accounts'),
                onChanged: (value) => setState(() => autoCreateUsers = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final nav = Navigator.of(context);
            nav.pop(LdapConfig(
              url: url,
              starttls: starttls,
              autoCreateUsers: autoCreateUsers,
              useFilter: useFilter,
              dnTemplate: dnTemplate,
              bindDn: bindDn,
              bindPassword: bindPassword,
              baseDn: baseDn,
              filterTemplate: filterTemplate,
            ));
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
