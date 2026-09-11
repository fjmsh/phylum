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
          builder: (context, state) => ListTile(
            title: Text('Password Login'),
            leading: Icon(Icons.password),
            subtitle: Text(state.passwordBackend.descriptor),
            onTap: state.isPasswordBackendFixed()
                ? null
                : () async {
                    final backend = await showOptionsDialog(
                      context,
                      titleText: 'Password Auth Backend',
                      [
                        PasswordBackend.none,
                        PasswordBackend.crypt,
                        PasswordBackend.ldap,
                      ],
                      (item) => ListTile(title: Text(item.descriptor)),
                    );
                    if (backend == null || !context.mounted) return;

                    _bloc.passwordBackend = backend;
                  },
          ),
        ),
        BlocBuilder<PasswordConfigCubit, PasswordConfigState>(
          bloc: _bloc,
          builder: (context, state) {
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
              previous.passwordBackend != current.passwordBackend,
        ),
        BlocBuilder<PasswordConfigCubit, PasswordConfigState>(
          bloc: _bloc,
          builder: (context, state) =>
              state.passwordBackend == PasswordBackend.crypt
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
              previous.passwordBackend != current.passwordBackend ||
              previous.mailEnabled != current.mailEnabled ||
              previous.resetEnabled != current.resetEnabled,
        ),
      ],
    );
  }
}
