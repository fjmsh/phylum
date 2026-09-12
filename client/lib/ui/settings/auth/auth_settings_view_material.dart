import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/util/dialogs.dart';

import '../../config/auth/auth_config.dart';
import '../../config/auth/auth_config_form.dart';
import '../../config/auth/auth_config_cubit.dart';

class MaterialAuthSettingsView extends StatelessWidget {
  final AuthConfigCubit _configBloc;

  const MaterialAuthSettingsView({super.key, required this._configBloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 18,
      children: [
        AuthConfigForm(bloc: _configBloc),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 18,
          children: [
            Builder(
              builder: (context) {
                final requestInFlight = context
                    .select<RemoteConfigState<AuthConfigFields>, bool>(
                      (state) =>
                          state is RemoteConfigStateLoaded<AuthConfigFields> &&
                          state.saving,
                    );
                return TextButton(
                  onPressed: requestInFlight
                      ? null
                      : () {
                          final state = context
                              .read<RemoteConfigState<AuthConfigFields>>();
                          if (state
                              is RemoteConfigStateLoaded<AuthConfigFields>) {
                            _configBloc.reset();
                          }
                        },
                  child: Text('Reset'),
                );
              },
            ),
            Builder(
              builder: (context) {
                // final configValid = context.select<AuthConfigFormCubit, bool>(
                //   (bloc) => bloc.state.valid,
                // );
                final requestInFlight = context
                    .select<RemoteConfigState<AuthConfigFields>, bool>(
                      (state) =>
                          state is RemoteConfigStateLoaded<AuthConfigFields> &&
                          state.saving,
                    );
                return TextButton(
                  onPressed: requestInFlight
                      ? null
                      : () async {
                          final config = _configBloc.validateConfig();

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
                        },
                  child: Text('Save'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
