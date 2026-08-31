import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form.dart';
import 'package:phylum/ui/settings/mail/form/mail_config_form.dart';
import 'package:phylum/ui/setup/db/db_config_form.dart';
import 'package:phylum/ui/setup/setup_config.dart';
import 'package:phylum/ui/setup/setup_cubit.dart';
import 'package:phylum/ui/setup/user/user_config_form.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/single_child_widget.dart';

import 'config_check_result.dart';

enum SetupStep { database, mail, auth, user }

class SetupPage extends StatefulWidget {
  final String instanceUrl;
  final SetupConfig config;

  const SetupPage({super.key, required this.instanceUrl, required this.config});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late final _bloc = SetupCubit(
    instanceUrl: widget.instanceUrl,
    config: widget.config,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instance Setup'),
        leading: CloseButton(
          onPressed: () async {
            final remain =
                await showAlertDialog(
                  context,
                  title: 'Abort configuration?',
                  positiveText: 'No',
                  negativeText: 'Yes',
                ) ??
                true;
            if (remain || !context.mounted) return;
            context.read<PhylumRouterDelegate>().go(HomeRoute());
          },
        ),
      ),
      body: ResponsiveViewport(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<SetupCubit, SetupState>(
                bloc: _bloc,
                builder: (context, state) {
                  return SingleChildScrollView(
                    child: _buildBody(context, state),
                  );
                },
                buildWhen: (previous, current) =>
                    previous.runtimeType != current.runtimeType,
              ),
            ),
            TextButtonTheme(
              data: TextButtonThemeData(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                ),
              ),
              child: BlocBuilder<SetupCubit, SetupState>(
                bloc: _bloc,
                builder: (context, state) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: state.hasPrevious
                            ? () => _bloc.previousStep()
                            : null,
                        child: Text('PREV'),
                      ),
                      TextButton(
                        onPressed: () => _next(context),
                        child: state.hasNext
                            ? const Text('NEXT')
                            : const Text('FINISH'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SetupState state) {
    return switch (state) {
      SetupStateDb() => DbConfigForm(
        bloc: _bloc.dbBloc,
        onFormSubmitted: _next,
      ),
      SetupStateMail() => MailConfigForm(
        bloc: _bloc.mailBloc,
        onFormSubmitted: _next,
      ),
      SetupStateAuth() => AuthConfigForm(bloc: _bloc.authBloc),
      SetupStateUser() => UserConfigForm(
        bloc: _bloc.userBloc,
        onFormSubmitted: _next,
      ),
    };
  }

  void _next(BuildContext context) {
    switch (_bloc.state) {
      case SetupStateDb():
        onDbNext(context);
      case SetupStateMail():
        onMailNext(context);
      case SetupStateAuth():
        onAuthNext(context);
      case SetupStateUser():
        onUserNext(context);
    }
  }

  Future<void> onDbNext(BuildContext context) async {
    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Database Config');
    final result = await _bloc.dbBloc.checkConfig();
    nav.pop();

    if (!context.mounted) return;

    final config = await handleConfigCheckResult(
      context,
      result,
      handleDbWarnings,
    );
    if (config != null) {
      _bloc.configureDb(config: config, wipeDb: false);
    }
  }

  Future<bool> handleDbWarnings(
    String code,
    Map<String, dynamic> config,
  ) async {
    if (code == 'not_empty') {
      final wipeDb = await showAlertDialog(
        context,
        title: 'Warning',
        message: "The database is not empty.",
        positiveText: 'Wipe Data',
        negativeText: 'Continue Anyway',
      );
      if (wipeDb != null) {
        _bloc.configureDb(config: config, wipeDb: wipeDb);
      }
      return true;
    }
    return false;
  }

  Future<void> onMailNext(BuildContext context) async {
    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Mail Config');
    final result = await _bloc.mailBloc.checkConfig();
    nav.pop();

    if (!context.mounted) return;
    final config = await handleConfigCheckResult(context, result);
    if (config != null) {
      _bloc.configureMail(config: config);
    }
  }

  Future<void> onAuthNext(BuildContext context) async {
    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Auth Config');
    final result = await _bloc.authBloc.checkConfig();
    nav.pop();

    if (!context.mounted) return;
    final config = await handleConfigCheckResult(context, result);
    if (config != null) {
      _bloc.configureAuth(config: config);
    }
  }

  Future<void> onUserNext(BuildContext context) async {
    final nav = Navigator.of(context);
    final config = _bloc.userBloc.validateConfig();
    if (config == null) return;

    showProgressDialog(context, message: 'Finalizing Instance Configuration');
    final result = await _bloc.configureUser(userConfig: config);
    nav.pop();

    if (!context.mounted) return;

    switch (result) {
      case FinalizeSuccess():
        await showAlertDialog(context, title: 'Instance configured');
        if (!context.mounted) return;
        context.read<PhylumRouterDelegate>().go(const HomeRoute());
      case FinalizeError():
        showAlertDialog(context, title: result.title, message: result.message);
    }
  }

  Future<Map<String, dynamic>?> handleConfigCheckResult(
    BuildContext context,
    ConfigCheckResult result, [
    Future<bool> Function(String, Map<String, dynamic>)? handleWarnings,
  ]) async {
    switch (result) {
      case ConfigInvalid(error: null):
        return null;
      case ConfigInvalid(error: String error):
        showAlertDialog(
          context,
          title: 'Invalid Configuration',
          message: error,
        );
        return null;
      case ConfigCheckSuccess(config: Map<String, dynamic> config):
        _bloc.configureAuth(config: config);
      case ConfigCheckError(config: Map<String, dynamic> config):
        final remain = await showAlertDialog(
          context,
          title: result.title,
          message: result.message,
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          return config;
        }
      case ConfigCheckWarning(
        code: String code,
        config: Map<String, dynamic> config,
      ):
        if (handleWarnings != null && await handleWarnings(code, config)) {
          return null;
        }
        if (!context.mounted) return null;
        final remain = await showAlertDialog(
          context,
          title: 'Warning',
          message:
              'The server returned an unrecognized warning when trying to check the configuration.\n\n'
              'Warning code: ${result.code}',
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          return config;
        }
    }
    return null;
  }

  void finalize(BuildContext context) async {}
}

class ResponsiveViewport extends SingleChildStatelessWidget {
  const ResponsiveViewport({super.key, super.child});

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    if (MediaQuery.sizeOf(context).width > maxViewportWidthSmall) {
      return Center(child: SizedBox(width: 640, child: child));
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: child);
  }
}
