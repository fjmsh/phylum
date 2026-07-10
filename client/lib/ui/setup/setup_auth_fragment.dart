import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/config/mail_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

import '../settings/auth/util/crypt.dart';
import '../settings/auth/util/ldap.dart';
import '../settings/auth/util/openid.dart';

class SetupAuthFragment extends StatefulWidget {
  final String instanceUrl;
  final void Function() onPrevPress;
  final void Function() onNextPress;

  const SetupAuthFragment({
    super.key,
    required this.instanceUrl,
    required this.onPrevPress,
    required this.onNextPress,
  });

  @override
  State<SetupAuthFragment> createState() => _SetupAuthFragmentState();
}

class _SetupAuthFragmentState extends State<SetupAuthFragment> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (!context.read<MailConfig>().enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthController>().passwordlessLoginEnabled = false;
        context.read<AuthController>().passwordConfig = context
            .read<AuthConfig>()
            .passwordConfig
            .copyWith(resetEnabled: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: buildContents(context))),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: widget.onPrevPress, child: Text('PREV')),
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
    final config = context.watch<AuthConfig>();
    final mailEnabled = context.select<MailConfig, bool>(
      (config) => config.enabled,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Auth', style: Theme.of(context).textTheme.headlineSmall),
        SwitchListTile(
          title: Text('Enable Passwordless Email Login'),
          subtitle: mailEnabled ? null : Text('Requires Email'),
          secondary: Icon(Icons.email),
          value: mailEnabled && config.passwordlessLoginEnabled,
          onChanged: mailEnabled
              ? (value) =>
                    context.read<AuthController>().passwordlessLoginEnabled =
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
              context.read<AuthController>().passwordConfig = context
                  .read<AuthConfig>()
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
              context.read<AuthController>().addOpenIDConfig(openIDConfig);
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
              context.read<AuthController>().replaceOpenIDConfig(
                cfg,
                openIDConfig,
              );
            },
            trailing: IconButton(
              onPressed: () =>
                  context.read<AuthController>().removeOpenIDConfig(cfg),
              icon: Icon(Icons.delete),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPasswordAuthSection(BuildContext context, PasswordConfig config) {
    final mailEnabled = context.select<MailConfig, bool>(
      (config) => config.enabled,
    );
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

            context.read<AuthController>().passwordConfig = config;
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
                widget.instanceUrl,
              );
              if (cryptConfig == null || !context.mounted) return;
              context.read<AuthController>().passwordConfig = config.copyWith(
                cryptConfig: cryptConfig,
              );
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
              ? (value) => context.read<AuthController>().passwordConfig =
                    config.copyWith(resetEnabled: value)
              : null,
        ),
      ],
    );
  }

  Future<void> validateAndNext(BuildContext context) async {
    if (formKey.currentState?.validate() == false) return;
    final config = context.read<AuthConfig>();
    if (!config.passwordLoginEnabled &&
        !config.passwordlessLoginEnabled &&
        config.openIdConfigs.isEmpty) {
      showAlertDialog(
        context,
        message: 'You must set up at least 1 login method',
      );
      return;
    }
    widget.onNextPress();
  }
}

class AuthController extends StateNotifier<AuthConfig> {
  AuthController() : super(AuthConfig.defaults());

  set passwordlessLoginEnabled(bool enabled) {
    state = state.copyWith(passwordlessLoginEnabled: enabled);
  }

  set passwordConfig(PasswordConfig config) {
    state = state.copyWith(passwordConfig: config);
  }

  void addOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(
      openIdConfigs: [...state.openIdConfigs, config].toList(growable: false),
    );
  }

  void replaceOpenIDConfig(OpenIDConfig old, OpenIDConfig config) {
    state = state.copyWith(
      openIdConfigs: state.openIdConfigs
          .map((e) => e == old ? config : e)
          .toList(growable: false),
    );
  }

  void removeOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(
      openIdConfigs: state.openIdConfigs
          .whereNot((e) => e == config)
          .toList(growable: false),
    );
  }
}
