import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/util/dialogs.dart';

import 'mail_config.dart';
import 'form/mail_config_form.dart';
import 'form/mail_config_form_cubit.dart';

class MaterialMailConfigPane extends StatelessWidget {
  final MailConfigCubit _bloc;
  const MaterialMailConfigPane({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 18,
      children: [
        MailConfigForm(
          bloc: _bloc,
          onFormSubmitted: (context) {
            if (!isSaving(context)) {
              save(context);
            }
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 18,
          children: [
            Builder(
              builder: (context) {
                return TextButton(
                  onPressed: isSaving(context)
                      ? null
                      : () {
                          final state = context
                              .read<RemoteConfigState<MailConfigFields>>();
                          if (state
                              is RemoteConfigStateLoaded<MailConfigFields>) {
                            context.read<MailConfigCubit>().reset(state.config);
                          }
                        },
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
    return context.select<RemoteConfigState<MailConfigFields>, bool>(
      (state) =>
          state is RemoteConfigStateLoaded<MailConfigFields> && state.saving,
    );
  }

  void save(BuildContext context) async {
    final config = _bloc.validateConfig();

    if (config == null) return;

    final error = await context
        .read<RemoteConfigController<MailConfigFields>>()
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
        title: 'Failed to update Mail Config',
        message: error,
      );
    }
  }
}
