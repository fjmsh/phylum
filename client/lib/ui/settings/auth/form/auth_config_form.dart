import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form_cubit.dart';
import 'package:phylum/ui/settings/auth/form/openid_config_cubit.dart';
import 'package:phylum/ui/settings/auth/form/openid_config_dialog.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/util/dialogs.dart';

import 'crypt_config_form.dart';
import 'ldap_config_form.dart';

class AuthConfigForm extends StatelessWidget {
  final AuthConfigFormCubit bloc;

  const AuthConfigForm({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: PasswordlessLoginSwitch(bloc: bloc),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: PasswordAuthForm(bloc: bloc),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: OpenIDConfigList(bloc: bloc),
          ),
        ),
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
              value: state.mailEnabled && state.passwordlessLoginEnabled,
              onChanged: state.mailEnabled
                  ? (value) => bloc.passwordlessLoginEnabled = value
                  : null,
            );
          },
          buildWhen: (previous, current) {
            return previous.mailEnabled != current.mailEnabled ||
                previous.passwordlessLoginEnabled !=
                    current.passwordlessLoginEnabled;
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
        BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
          bloc: bloc,
          builder: (context, state) => ListTile(
            title: Text('Password Login'),
            leading: Icon(Icons.password),
            subtitle: Text(state.passwordBackend.descriptor),
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

              bloc.passwordBackend = backend;
            },
          ),
        ),
        BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
          bloc: bloc,
          builder: (context, state) {
            return switch (state.passwordBackend) {
              .crypt => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CryptConfigForm(
                  mailEnabled: state.mailEnabled,
                  bloc: bloc.cryptBloc,
                ),
              ),
              .ldap => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: LdapConfigForm(bloc: bloc.ldapBloc),
              ),
              _ => Container(),
            };
          },
          buildWhen: (previous, current) =>
              previous.mailEnabled != current.mailEnabled ||
              previous.passwordBackend != current.passwordBackend,
        ),
      ],
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
        return buildList(context, state.openIdConfigs);
      },
      buildWhen: (previous, current) => !const DeepCollectionEquality().equals(
        previous.openIdConfigs,
        current.openIdConfigs,
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
              final config = await OpenIDConfigDialog.show(
                context,
                config: OpenIDConfig.createFromConfig(
                  RemoteConfig.empty(OidcConfigFields.instance),
                ),
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
              final config = await OpenIDConfigDialog.show(
                context,
                config: e.value,
              );
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
