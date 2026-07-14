import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/auth/api/update_request.dart';
import 'package:phylum/ui/settings/auth/auth_config_controller.dart';
import 'package:phylum/ui/settings/auth/util/crypt.dart';
import 'package:phylum/ui/settings/auth/util/ldap.dart';
import 'package:phylum/ui/settings/auth/util/openid.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class AuthConfigForm extends StatefulWidget {
  const AuthConfigForm({super.key});

  @override
  State<AuthConfigForm> createState() => _AuthConfigFormState();
}

class _AuthConfigFormState extends State<AuthConfigForm> {
  bool requestInFlight = false;
  @override
  Widget build(BuildContext context) {
    final config = context.select<AuthConfigState, AuthConfig>(
      (s) => s.config!,
    );
    final mailEnabled = context.watch<PhylumAccount>().config.mail;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text('Enable Passwordless Email Login'),
          subtitle: mailEnabled ? null : Text('Requires Email'),
          secondary: Icon(Icons.email),
          value: mailEnabled && config.passwordlessLoginEnabled,
          onChanged: mailEnabled
              ? (value) =>
                    context
                            .read<AuthConfigController>()
                            .passwordlessLoginEnabled =
                        value
              : null,
        ),
        const SizedBox(height: 18),
        ListTile(
          dense: true,
          title: Text(
            'Password Auth',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          title: Text('Enable Password Auth'),
          secondary: Icon(Icons.password),
          value: config.passwordLoginEnabled,
          onChanged: (value) =>
              context.read<AuthConfigController>().passwordConfig = config
                  .passwordConfig
                  .copyWith(backend: PasswordBackend.crypt),
          // subtitle:
          //     config.passwordConfig != null ? Text(config.toString()) : null,
        ),
        if (config.passwordLoginEnabled)
          buildPasswordAuthSection(context, config.passwordConfig),
        const SizedBox(height: 18),
        ListTile(
          dense: true,
          title: Text(
            'OpenID Login',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            onPressed: () async {
              final openIDConfig = await OidcDialog.show(
                context,
                OpenIDConfig.empty(),
              );
              if (openIDConfig == null || !context.mounted) return;
              context.read<AuthConfigController>().addOpenIDConfig(
                openIDConfig,
              );
            },
            icon: Icon(Icons.add),
            tooltip: 'Add OpenID Login Provider',
          ),
        ),
        ...config.openIdConfigs.mapIndexed(
          (i, cfg) => ListTile(
            title: Text(cfg.name),
            subtitle: Text(cfg.issuerUrl),
            onTap: () async {
              final openIDConfig = await OidcDialog.show(context, cfg);
              if (openIDConfig == null || !context.mounted) return;
              context.read<AuthConfigController>().replaceOpenIDConfig(
                cfg,
                openIDConfig,
              );
            },
            trailing: IconButton(
              onPressed: () =>
                  context.read<AuthConfigController>().removeOpenIDConfig(cfg),
              icon: Icon(Icons.delete),
            ),
          ),
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
    );
  }

  Widget buildPasswordAuthSection(BuildContext context, PasswordConfig config) {
    final mailEnabled = context.watch<PhylumAccount>().config.mail;
    return Column(
      children: [
        ListTile(
          title: Text('Backend'),
          leading: Icon(Icons.storage),
          subtitle: Text(config.backend.descriptor),
          onTap: () async {
            final backend = await showOptionsDialog(
              context,
              titleText: 'Password Auth Backend',
              [PasswordBackend.crypt, PasswordBackend.ldap],
              (item) => ListTile(title: Text(item.descriptor)),
            );
            if (backend == null || !context.mounted) return;

            config = config.copyWith(backend: backend);
            if (backend == PasswordBackend.ldap) {
              final ldapConfig = await LdapConfigDialog.show(
                context,
                config.ldapConfig,
              );
              if (ldapConfig == null || !context.mounted) return;
              config = config.copyWith(ldapConfig: ldapConfig);
            }

            context.read<AuthConfigController>().passwordConfig = config;
          },
        ),
        if (config.backend == PasswordBackend.crypt)
          ListTile(
            title: Text('KDF'),
            subtitle: Text(config.cryptConfig.toString()),
            leading: Icon(Icons.key),
            onTap: () async {
              final cryptConfig = await configureKDF(
                context,
                config.cryptConfig,
                context.read<PhylumAccount>().apiClient.serverUrl.toString(),
              );
              if (cryptConfig == null || !context.mounted) return;
              context.read<AuthConfigController>().passwordConfig = config
                  .copyWith(cryptConfig: cryptConfig);
            },
          )
        else if (config.backend == PasswordBackend.ldap)
          ListTile(
            title: Text('LDAP Configuration'),
            subtitle: Text(config.ldapConfig.toString()),
            leading: Icon(Icons.key),
            onTap: () async {
              final ldapConfig = await LdapConfigDialog.show(
                context,
                config.ldapConfig,
              );
              if (ldapConfig == null || !context.mounted) return;
              config = config.copyWith(ldapConfig: ldapConfig);
            },
          ),
        SwitchListTile(
          title: Text('Self-Serve Password Reset'),
          subtitle: !mailEnabled
              ? const Text('Requires Email')
              : config.backend != PasswordBackend.crypt
              ? const Text('Only supported for DB backend')
              : null,
          secondary: Icon(Icons.refresh),
          value: mailEnabled && config.backend == PasswordBackend.crypt
              ? config.resetEnabled
              : false,
          onChanged: mailEnabled && config.backend == PasswordBackend.crypt
              ? (value) => context.read<AuthConfigController>().passwordConfig =
                    config.copyWith(resetEnabled: value)
              : null,
        ),
      ],
    );
  }

  Future<void> save(BuildContext context) async {
    final config = context.read<AuthConfigState>().config!;
    if (!config.passwordLoginEnabled &&
        !config.passwordlessLoginEnabled &&
        config.openIdConfigs.isEmpty) {
      showAlertDialog(
        context,
        message: 'You must set up at least 1 login method',
      );
      return;
    }

    if (requestInFlight) return;

    setState(() => requestInFlight = true);
    final result = await context.read<PhylumAccount>().apiClient.sendRequest(
      UpdateAuthConfigRequest(
        old: AuthConfig.defaults(), // TODO: Fix
        config: config,
      ),
    );
    if (!context.mounted) return;
    setState(() => requestInFlight = false);

    if (result is ApiSuccessResponse) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auth Config Updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      showAlertDialog(
        context,
        title: 'Failed to update Auth Config',
        message: result.description,
      );
    }
  }
}
