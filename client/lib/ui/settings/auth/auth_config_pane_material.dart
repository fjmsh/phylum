import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:phylum/util/dialogs.dart';

import 'auth_config.dart';
import 'auth_config_pane_cubit.dart';
import 'form/auth_config_form.dart';
import 'form/auth_config_form_cubit.dart';

class MaterialAuthConfigPane extends StatelessWidget {
  final AuthConfigPaneCubit _configBloc;

  const MaterialAuthConfigPane({super.key, required this._configBloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 18,
      children: [
        AuthConfigForm(bloc: context.read()),
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
                            _configBloc.reset(state.config);
                          }
                        },
                  child: Text('Reset'),
                );
              },
            ),
            Builder(
              builder: (context) {
                final configValid = context.select<AuthConfigFormCubit, bool>(
                  (bloc) => bloc.state.config.valid,
                );
                final requestInFlight = context
                    .select<RemoteConfigState<AuthConfigFields>, bool>(
                      (state) =>
                          state is RemoteConfigStateLoaded<AuthConfigFields> &&
                          state.saving,
                    );
                return TextButton(
                  onPressed: requestInFlight || !configValid
                      ? null
                      : () async {
                          final config = context
                              .read<AuthConfigFormCubit>()
                              .validate();

                          if (config == null) {
                            return;
                          }

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
