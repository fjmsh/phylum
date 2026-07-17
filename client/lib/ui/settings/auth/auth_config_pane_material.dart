import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/util/dialogs.dart';

import 'auth_config_pane_cubit.dart';
import 'form/auth_config_form.dart';
import 'form/auth_config_form_cubit.dart';

class MaterialAuthConfigPane extends StatelessWidget {
  final AuthConfigPaneCubit _configBloc;
  final AuthConfigSaveCubit _saveBloc;

  const MaterialAuthConfigPane({
    super.key,
    required this._configBloc,
    required this._saveBloc,
  });

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
            BlocBuilder<AuthConfigSaveCubit, AuthConfigSaveState>(
              bloc: _saveBloc,
              builder: (context, state) {
                final requestInFlight = context
                    .select<AuthConfigSaveCubit, bool>(
                      (bloc) => bloc.state.requestInFlight,
                    );
                return TextButton(
                  onPressed: requestInFlight ? null : () => _configBloc.reset(),
                  child: Text('Reset'),
                );
              },
              buildWhen: (previous, current) =>
                  previous.requestInFlight != current.requestInFlight,
            ),
            Builder(
              builder: (context) {
                final configValid = context.select<AuthConfigFormCubit, bool>(
                  (bloc) => bloc.state.config.valid,
                );
                final requestInFlight = context
                    .select<AuthConfigSaveCubit, bool>(
                      (bloc) => bloc.state.requestInFlight,
                    );
                return TextButton(
                  onPressed: requestInFlight || !configValid
                      ? null
                      : () async {
                          final config = context
                              .read<AuthConfigFormCubit>()
                              .state
                              .config;

                          final error = await context
                              .read<AuthConfigSaveCubit>()
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
