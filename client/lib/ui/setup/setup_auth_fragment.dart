import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form_cubit.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class SetupAuthFragment extends StatefulWidget {
  final AuthConfigSetupCubit _authBloc;
  final void Function() onPrevPress;
  final void Function() onNextPress;

  const SetupAuthFragment({
    super.key,
    required this._authBloc,
    required this.onPrevPress,
    required this.onNextPress,
  });

  @override
  State<SetupAuthFragment> createState() => _SetupAuthFragmentState();
}

class _SetupAuthFragmentState extends State<SetupAuthFragment> {
  @override
  void initState() {
    super.initState();

    if (!context.read<MailConfig>().enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget._authBloc.passwordlessLoginEnabled = false;
        widget._authBloc.passwordConfig = widget
            ._authBloc
            .state
            .config
            .passwordConfig
            .copyWith(resetEnabled: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: AuthConfigForm(bloc: widget._authBloc),
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
              TextButton(onPressed: widget.onPrevPress, child: Text('PREV')),
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
    if (!widget._authBloc.state.config.valid) {
      showAlertDialog(
        context,
        message: 'You must set up at least 1 login method',
      );
      return;
    }
    widget.onNextPress();
  }
}

class AuthConfigSetupCubit extends AuthConfigFormCubit {
  AuthConfigSetupCubit() : super(initialConfig: .defaults());

  @override
  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) async {
    return KDFTestFailure(title: 'Unimplemented');
  }
}
