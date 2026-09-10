import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/config/auth/auth_config_form_cubit.dart';
import 'package:phylum/ui/config/auth/openid/openid_config_cubit.dart';
import 'package:phylum/ui/config/auth/openid/openid_config_dialog.dart';
import 'package:phylum/ui/config/auth/openid/openid_config_fields.dart';
import 'package:phylum/ui/config/auth/password/password_config_form.dart';
import 'package:phylum/ui/config/config.dart';

class AuthConfigForm extends StatelessWidget {
  final AuthConfigCubit bloc;

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
  final AuthConfigCubit bloc;

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
        BlocBuilder<AuthConfigCubit, AuthConfigFormState>(
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
  final AuthConfigCubit bloc;

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
        PasswordConfigForm(bloc: bloc.passwordBloc),
      ],
    );
  }
}

class OpenIDConfigList extends StatelessWidget {
  final AuthConfigCubit bloc;
  const OpenIDConfigList({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthConfigCubit, AuthConfigFormState>(
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
                  RemoteConfig.empty(OpenidConfigFields.instance),
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
              onPressed: e.value.hasFixedFields
                  ? null
                  : () => bloc.removeOpenIDConfig(e.key),
              icon: Icon(Icons.delete),
            ),
          ),
        ),
      ],
    );
  }
}
