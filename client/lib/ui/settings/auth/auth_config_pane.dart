import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/ui/settings/auth/auth_config_controller.dart';
import 'package:phylum/util/dialogs.dart';

import 'auth_config_form.dart';

class AuthConfigPane extends StatefulWidget {
  final AuthConfig initialConfig;
  final Function(AuthConfig) onConfigUpdated;

  const AuthConfigPane({
    super.key,
    required this.initialConfig,
    required this.onConfigUpdated,
  });

  @override
  State<AuthConfigPane> createState() => _AuthConfigPaneState();
}

class _AuthConfigPaneState extends State<AuthConfigPane> {
  late final bloc = AuthConfigFormCubit(
    context,
    initialConfig: widget.initialConfig,
    onConfigUpdated: widget.onConfigUpdated,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 18,
      children: [
        AuthConfigForm(bloc: bloc),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 18,
          children: [
            BlocBuilder<AuthConfigFormCubit, AuthConfigFormState>(
              bloc: bloc,
              builder: (context, AuthConfigFormState state) {
                return ElevatedButton(
                  onPressed: state.requestInFlight || !state.config.valid
                      ? null
                      : () async {
                          final error = await bloc.save();
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
              buildWhen: (previous, current) =>
                  previous.requestInFlight != current.requestInFlight ||
                  previous.config.valid != current.config.valid,
            ),
          ],
        ),
      ],
    );
  }
}
