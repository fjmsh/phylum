import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config_form.dart';
import 'package:phylum/ui/config/auth/ldap/ldap_config_form.dart';
import 'package:phylum/util/dialogs.dart';

import 'password_config.dart';
import 'password_config_cubit.dart';

class PasswordConfigForm extends StatelessWidget {
  final PasswordConfigCubit _bloc;

  const PasswordConfigForm({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<PasswordConfigCubit, PasswordConfigState>(
          bloc: _bloc,
          builder: (context, state) => SwitchListTile(
            title: Text('Enable Password Login'),
            secondary: Icon(Icons.password),
            value: state.enabled,
            onChanged: state.isPasswordBackendFixed()
                ? null
                : (bool value) {
                    _bloc.enabled = value;
                  },
          ),
          buildWhen: (previous, current) => previous.enabled != current.enabled,
        ),
        BlocBuilder<PasswordConfigCubit, PasswordConfigState>(
          bloc: _bloc,
          builder: (context, state) => state.enabled
              ? ListTile(
                  title: Text('Auth Backend'),
                  leading: switch (state.passwordBackend) {
                    .none => const Icon(Icons.remove_moderator_sharp),
                    .crypt => const Icon(Icons.shield),
                    .ldap => const Icon(Icons.lan),
                  },
                  subtitle: Text(state.passwordBackend.descriptor),
                  onTap: state.isPasswordBackendFixed()
                      ? null
                      : () async {
                          final backend = await showOptionsDialog(
                            context,
                            titleText: 'Select Auth Backend',
                            [PasswordBackend.crypt, PasswordBackend.ldap],
                            (item) => ListTile(title: Text(item.descriptor)),
                          );
                          if (backend == null || !context.mounted) return;

                          _bloc.passwordBackend = backend;
                        },
                )
              : Container(),
          buildWhen: (previous, current) =>
              previous.enabled != current.enabled ||
              previous.passwordBackend != current.passwordBackend,
        ),
        BlocBuilder<PasswordConfigCubit, PasswordConfigState>(
          bloc: _bloc,
          builder: (context, state) {
            if (!state.enabled) return Container();
            return switch (state.passwordBackend) {
              .crypt => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CryptConfigForm(bloc: _bloc.cryptBloc),
              ),
              .ldap => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: LdapConfigForm(bloc: _bloc.ldapBloc),
              ),
              _ => Container(),
            };
          },
          buildWhen: (previous, current) =>
              previous.enabled != current.enabled ||
              previous.passwordBackend != current.passwordBackend,
        ),
        BlocBuilder<PasswordConfigCubit, PasswordConfigState>(
          bloc: _bloc,
          builder: (context, state) =>
              state.enabled && state.passwordBackend == .crypt
              ? SwitchListTile(
                  title: Text('Self-Serve Password Reset'),
                  subtitle: !state.mailEnabled
                      ? const Text('Requires Email')
                      : null,
                  secondary: Icon(Icons.refresh),
                  value: state.mailEnabled ? state.resetEnabled : false,
                  onChanged: state.isResetEnabledFixed() || !state.mailEnabled
                      ? null
                      : (value) => _bloc.resetEnabled = value,
                )
              : Container(),
          buildWhen: (previous, current) =>
              previous.enabled != current.enabled ||
              previous.passwordBackend != current.passwordBackend ||
              previous.mailEnabled != current.mailEnabled ||
              previous.resetEnabled != current.resetEnabled,
        ),
      ],
    );
  }
}
