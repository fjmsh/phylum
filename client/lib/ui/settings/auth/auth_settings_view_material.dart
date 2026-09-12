import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/util/dialogs.dart';

import '../../config/auth/auth_config.dart';
import '../../config/auth/auth_config_form.dart';
import '../../config/auth/auth_config_cubit.dart';

class MaterialAuthSettingsView extends StatelessWidget {
  final AuthConfigCubit _bloc;

  const MaterialAuthSettingsView({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 18,
      children: [
        AuthConfigForm(bloc: _bloc),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 18,
          children: [
            Builder(
              builder: (context) {
                return TextButton(
                  onPressed: isSaving(context) ? null : () => _bloc.reset(),
                  child: Text('Reset'),
                );
              },
            ),
            Builder(
              builder: (context) {
                return TextButton(
                  onPressed: isSaving(context) ? null : () => save(context),
                  child: Text('Save'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  bool isSaving(BuildContext context) {
    return context.select<RemoteConfigState<AuthConfigFields>, bool>(
      (state) =>
          state is RemoteConfigStateLoaded<AuthConfigFields> && state.saving,
    );
  }

  void save(BuildContext context) async {
    final config = _bloc.validateConfig();

    if (config == null) return;

    final error = await context
        .read<RemoteConfigController<AuthConfigFields>>()
        .save(config: config);
    if (!context.mounted) return;
    if (error == null) {
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
        message: error,
      );
    }
  }
}
