import 'package:flutter/material.dart';
import 'package:phylum/ui/setup/db/db_config.dart';
import 'package:phylum/ui/setup/db/db_config_form.dart';
import 'package:phylum/ui/setup/db/db_config_form_cubit.dart';
import 'package:phylum/util/dialogs.dart';

class SetupDbFragment extends StatelessWidget {
  final DbConfigFormCubit _bloc;
  final void Function() onNextPress;

  const SetupDbFragment({
    super.key,
    required this._bloc,
    required this.onNextPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DbConfigForm(bloc: _bloc, onFormSubmitted: validateAndNext),
          ),
        ),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: null, child: Text('PREV')),
              TextButton(
                onPressed: () => validateAndNext(context),
                child: Text('NEXT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> validateAndNext(BuildContext context) async {
    final config = _bloc.validate();
    if (config == null) return;

    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Email Config');
    final result = await _bloc.checkConfig(config);
    nav.pop();

    if (!context.mounted) return;

    switch (result) {
      case DbConfigCheckSuccess():
        onNextPress();
      case DbConfigCheckWarningNotEmpty():
        final response = await showAlertDialog(
          context,
          title: 'Warning',
          message: "The database is not empty.",
          positiveText: 'Continue anyway',
          negativeText: 'Wipe Data',
        );
        if (response == null) return;
        if (!response) {
          // config.setValue(DbConfigFields.fieldWipe, true);
        }
        onNextPress();
      case DbConfigCheckFailed():
        final remain = await showAlertDialog(
          context,
          title: 'Config Check Failed',
          message: result.error,
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          onNextPress();
        }
      case DbConfigCheckError():
        final remain = await showAlertDialog(
          context,
          title: result.title,
          message: result.message,
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          onNextPress();
        }
      case DbConfigCheckUnknownWarning():
        final remain = await showAlertDialog(
          context,
          title: 'Warning',
          message:
              'The server returned a warning when trying to check the configuration.\n\n'
              'Warning code: ${result.code}',
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          onNextPress();
        }
    }
  }
}
