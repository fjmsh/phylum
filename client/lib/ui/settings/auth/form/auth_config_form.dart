import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form_cubit.dart';
import 'package:phylum/ui/settings/auth/util/crypt.dart';
import 'package:phylum/ui/settings/auth/util/ldap.dart';
import 'package:phylum/ui/settings/auth/util/openid.dart';
import 'package:phylum/util/dialogs.dart';

class AuthConfigForm extends StatelessWidget {
  final AuthConfigFormCubit bloc;

  const AuthConfigForm({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        PasswordlessLoginSwitch(bloc: bloc),
        PasswordAuthForm(bloc: bloc),
        OpenIDConfigList(bloc: bloc),
      ],
    );
  }
}

class PasswordlessLoginSwitch extends StatelessWidget {
  final AuthConfigFormCubit bloc;

  const PasswordlessLoginSwitch({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          title: Text(
            'Passwordless Login',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
          bloc: bloc,
          builder: (context, state) {
            return SwitchListTile(
              title: Text('Enable Passwordless Email Login'),
              subtitle: bloc.state.mailEnabled ? null : Text('Requires Email'),
              secondary: Icon(Icons.email),
              value: state.mailEnabled && state.config.passwordlessLoginEnabled,
              onChanged: state.mailEnabled
                  ? (value) => bloc.passwordlessLoginEnabled = value
                  : null,
            );
          },
          buildWhen: (previous, current) {
            return previous.mailEnabled != current.mailEnabled ||
                previous.config.passwordlessLoginEnabled !=
                    current.config.passwordlessLoginEnabled;
          },
        ),
      ],
    );
  }
}

class PasswordAuthForm extends StatelessWidget {
  final AuthConfigFormCubit bloc;

  const PasswordAuthForm({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          title: Text(
            'Password Login',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
        //   bloc: bloc,
        //   builder: (context, state) {
        //     return SwitchListTile(
        //       title: Text('Enable Password Login'),
        //       secondary: Icon(Icons.password),
        //       value: state.config.passwordLoginEnabled,
        //       onChanged: (value) =>
        //           bloc.passwordConfig = state.config.passwordConfig.copyWith(
        //             backend: value
        //                 ? PasswordBackend.crypt
        //                 : PasswordBackend.none,
        //           ),
        //     );
        //   },
        //   buildWhen: (previous, current) =>
        //       previous.config.passwordLoginEnabled !=
        //       current.config.passwordLoginEnabled,
        // ),
        BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
          bloc: bloc,
          builder: (context, state) => ListTile(
            title: Text('Password Login'),
            leading: Icon(Icons.password),
            subtitle: Text(state.config.passwordConfig.backend.descriptor),
            onTap: () async {
              final backend = await showOptionsDialog(
                context,
                titleText: 'Password Login',
                [
                  PasswordBackend.none,
                  PasswordBackend.crypt,
                  PasswordBackend.ldap,
                ],
                (item) => ListTile(title: Text(item.descriptor)),
              );
              if (backend == null || !context.mounted) return;

              var config = state.config.passwordConfig.copyWith(
                backend: backend,
              );
              if (backend == PasswordBackend.ldap &&
                  config.ldapConfig == LdapConfig.defaults()) {
                final ldapConfig = await LdapConfigDialog.show(
                  context,
                  config.ldapConfig,
                );
                if (ldapConfig == null || !context.mounted) return;
                config = config.copyWith(
                  backend: PasswordBackend.ldap,
                  ldapConfig: ldapConfig,
                );
              }

              bloc.passwordConfig = config;
            },
          ),
        ),
        BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
          bloc: bloc,
          builder: (context, state) {
            return switch (state.config.passwordConfig.backend) {
              .crypt => buildCryptFields(
                context,
                state.config.passwordConfig,
                state.mailEnabled,
              ),
              .ldap => buildLdapFields(context, state.config.passwordConfig),
              _ => Container(),
            };
          },
          buildWhen: (previous, current) =>
              previous.mailEnabled != current.mailEnabled ||
              (previous.config.passwordConfig.backend ==
                      PasswordBackend.none) !=
                  (current.config.passwordConfig.backend ==
                      PasswordBackend.none) ||
              previous.config.passwordConfig != current.config.passwordConfig,
        ),
      ],
    );
  }

  Widget buildCryptFields(
    BuildContext context,
    PasswordConfig config,
    bool mailEnabled,
  ) {
    return Column(
      children: [
        ListTile(
          title: Text('KDF'),
          subtitle: Text(config.cryptConfig.description),
          leading: Icon(Icons.key),
          onTap: () async {
            final cryptConfig = await configureKDF(
              context,
              bloc,
              config.cryptConfig,
            );
            if (cryptConfig == null || !context.mounted) return;
            bloc.passwordConfig = config.copyWith(cryptConfig: cryptConfig);
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
              ? (value) =>
                    bloc.passwordConfig = config.copyWith(resetEnabled: value)
              : null,
        ),
      ],
    );
  }

  Widget buildLdapFields(BuildContext context, PasswordConfig config) {
    return ListTile(
      title: Text('LDAP Configuration'),
      subtitle: Text('Server: ${config.ldapConfig.url}'),
      leading: Icon(Icons.storage),
      onTap: () async {
        final ldapConfig = await LdapConfigDialog.show(
          context,
          config.ldapConfig,
        );
        if (ldapConfig == null || !context.mounted) return;
        bloc.passwordConfig = config.copyWith(ldapConfig: ldapConfig);
      },
    );
  }
}

class OpenIDConfigList extends StatelessWidget {
  final AuthConfigFormCubit bloc;
  const OpenIDConfigList({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
      bloc: bloc,
      builder: (context, state) {
        return buildList(context, state.config.openIdConfigs);
      },
      buildWhen: (previous, current) => !DeepCollectionEquality().equals(
        previous.config.openIdConfigs,
        current.config.openIdConfigs,
      ),
    );
  }

  Widget buildList(
    BuildContext context,
    Map<String, OpenIDConfig> openIdConfigs,
  ) {
    return Column(
      children: [
        ListTile(
          dense: true,
          title: Text(
            'OpenID Login',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            onPressed: () async {
              final config = await OidcDialog.show(
                context,
                OpenIDConfig.empty(),
              );
              if (config == null || !context.mounted) return;
              bloc.addOpenIDConfig(config);
            },
            icon: Icon(Icons.add),
            tooltip: 'Add OpenID Login Provider',
          ),
        ),
        ...openIdConfigs.entries.map(
          (e) => ListTile(
            title: Text(e.value.name),
            subtitle: Text(e.value.issuerUrl),
            onTap: () async {
              final config = await OidcDialog.show(context, e.value);
              if (config == null || !context.mounted) return;
              bloc.replaceOpenIDConfig(e.key, config);
            },
            trailing: IconButton(
              onPressed: () => bloc.removeOpenIDConfig(e.key),
              icon: Icon(Icons.delete),
            ),
          ),
        ),
      ],
    );
  }
}
