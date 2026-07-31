import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/auth/form/crypt_config_cubit.dart';
import 'package:phylum/util/dialogs.dart';

class CryptConfigForm extends StatelessWidget {
  final CryptConfigCubit _bloc;
  final bool _mailEnabled;

  const CryptConfigForm({
    super.key,
    required this._bloc,
    required this._mailEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<CryptConfigCubit, CryptConfigState>(
          bloc: _bloc,
          builder: (context, state) => state.shouldAllowKdfSelection
              ? ListTile(
                  title: Text('KDF'),
                  subtitle: Text(state.kdf.descriptor),
                  leading: Icon(Icons.key),
                  onTap: () async {
                    final kdf = await showOptionsDialog(
                      context,
                      titleText: 'Password Login',
                      [CryptKDF.argon2, CryptKDF.pbkdf2],
                      (item) => ListTile(title: Text(item.descriptor)),
                    );
                    if (kdf == null || !context.mounted) return;
                    _bloc.kdf = kdf;
                  },
                )
              : const SizedBox(),
          buildWhen: (previous, current) =>
              previous.kdf != current.kdf ||
              previous.shouldAllowKdfSelection !=
                  current.shouldAllowKdfSelection,
        ),
        // TODO: KDF params
        BlocBuilder<CryptConfigCubit, CryptConfigState>(
          bloc: _bloc,
          builder: (context, state) => SwitchListTile(
            title: Text('Self-Serve Password Reset'),
            subtitle: !_mailEnabled ? const Text('Requires Email') : null,
            secondary: Icon(Icons.refresh),
            value: _mailEnabled ? state.resetEnabled : false,
            onChanged: _mailEnabled
                ? (value) => _bloc.resetEnabled = value
                : null,
          ),
          buildWhen: (previous, current) =>
              previous.resetEnabled != current.resetEnabled,
        ),
      ],
    );
  }
}
