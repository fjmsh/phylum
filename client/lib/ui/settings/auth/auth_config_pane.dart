import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form_cubit.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

import 'auth_config_pane_cubit.dart';
import 'form/auth_config_form.dart';

class AuthConfigPane extends StatelessWidget {
  const AuthConfigPane._();

  static Widget create(
    BuildContext context, {
    required AuthConfig initialConfig,
    required void Function(AuthConfig) onConfigUpdated,
  }) {
    late final configBloc = AuthConfigPaneCubit(
      context.read(),
      initialConfig: initialConfig,
    );

    late final saveBloc = AuthConfigSaveCubit(
      account: context.read(),
      initialConfig: initialConfig,
      onConfigUpdated: onConfigUpdated,
    );
    return MultiProvider(
      providers: [
        BlocProvider<AuthConfigFormCubit>.value(value: configBloc),
        BlocProvider.value(value: saveBloc),
      ],
      builder: (context, child) => const AuthConfigPane._(),
    );
  }

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
                final configValid = context.select<AuthConfigFormCubit, bool>(
                  (bloc) => bloc.state.config.valid,
                );
                final requestInFlight = context
                    .select<AuthConfigSaveCubit, bool>(
                      (bloc) => bloc.state.requestInFlight,
                    );
                return ElevatedButton(
                  onPressed: requestInFlight || !configValid
                      ? null
                      : () async {
                          final config = context
                              .read<AuthConfigFormCubit>()
                              .state
                              .config;

                          final error = await context
                              .read<AuthConfigSaveCubit>()
                              .save(config);
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
