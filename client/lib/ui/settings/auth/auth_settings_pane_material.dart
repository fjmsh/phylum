import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/ui/config/config_check_result.dart';
import 'package:phylum/util/dialogs.dart';

import '../../config/auth/auth_config.dart';
import 'auth_settings_pane_cubit.dart';
import '../../config/auth/auth_config_form.dart';
import '../../config/auth/auth_config_form_cubit.dart';

class MaterialAuthSettingsPane extends StatelessWidget {
  final AuthConfigPaneCubit _configBloc;

  const MaterialAuthSettingsPane({super.key, required this._configBloc});

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
                          final result = await context
                              .read<AuthConfigCubit>()
                              .checkConfig();

                          if (!context.mounted) return;

                          switch (result) {
                            case ConfigInvalid():
                              return;
                            case ConfigCheckSuccess():
                              final error = await context
                                  .read<
                                    RemoteConfigController<AuthConfigFields>
                                  >()
                                  .save(config: result.config);
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
                              break;
                            case ConfigCheckError():
                            case ConfigCheckWarning():
                              throw UnimplementedError();
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
