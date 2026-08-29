import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form_cubit.dart';
import 'package:phylum/ui/settings/mail/form/mail_config_form.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/ui/setup/db/db_config_form.dart';
import 'package:phylum/ui/setup/db/db_config_form_cubit.dart';
import 'package:phylum/ui/setup/setup_config.dart';
import 'package:phylum/ui/setup/setup_cubit.dart';
import 'package:phylum/ui/setup/user/user_config_form.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:uri/uri.dart';

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
        finalize(context);
    }
  }

  Future<void> onDbNext(BuildContext context) async {
    final dbConfig = _bloc.dbBloc.validate();
    if (dbConfig == null) return;

    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Database Config');
    final result = await _bloc.dbBloc.checkConfig(dbConfig);
    nav.pop();

    if (!context.mounted) return;

    switch (result) {
      case DbConfigCheckSuccess():
        _bloc.configureDb(dbConfig: dbConfig, wipeDb: false);
      case DbConfigCheckWarningNotEmpty():
        final notWipe = await showAlertDialog(
          context,
          title: 'Warning',
          message: "The database is not empty.",
          positiveText: 'Continue anyway',
          negativeText: 'Wipe Data',
        );
        if (notWipe == null) return;
        _bloc.configureDb(dbConfig: dbConfig, wipeDb: !notWipe);
      case DbConfigCheckFailed():
        final remain = await showAlertDialog(
          context,
          title: 'Config Check Failed',
          message: result.error,
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          _bloc.configureDb(dbConfig: dbConfig, wipeDb: false);
        }
      case DbConfigCheckError():
        final remain = await showAlertDialog(
          context,
          title: result.title,
          message: result.message,
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          _bloc.configureDb(dbConfig: dbConfig, wipeDb: false);
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
          _bloc.configureDb(dbConfig: dbConfig, wipeDb: false);
        }
    }
  }

  Future<void> onMailNext(BuildContext context) async {
    final mailConfig = _bloc.mailBloc.validate();
    if (mailConfig == null) return;

    if (!mailConfig.getValue(MailConfigFields.fieldEnabled)) {
      _bloc.configureMail(mailConfig: mailConfig);
      return;
    }
    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Email Config');
    final error = await _bloc.mailBloc.checkConfig(mailConfig);
    nav.pop();
    if (error == null) {
      _bloc.configureMail(mailConfig: mailConfig);
    } else {
      if (!context.mounted) return;
      final remain = await showAlertDialog(
        context,
        title: 'Config Check Failed',
        message: error,
        negativeText: 'Continue Anyway',
      );
      if (remain == false) {
        _bloc.configureMail(mailConfig: mailConfig);
      }
    }
  }

  Future<void> onAuthNext(BuildContext context) async {
    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Database Config');

    final authConfigCheckResult = await _bloc.authBloc.checkConfig();
    nav.pop();
    if (!context.mounted) return;

    switch (authConfigCheckResult) {
      case AuthConfigInvalid():
        showAlertDialog(context, message: authConfigCheckResult.error);
        break;
      case AuthConfigValid():
        _bloc.configureAuth(authConfig: authConfigCheckResult.config);
        break;
    }
  }

  void finalize(BuildContext context) async {
    final builder = UriBuilder.fromUri(Uri.parse(widget.instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/finalize';
    final request = Request('post', builder.build());
    final data = {
      'config': {
        // 'db': context.read<DbConfig>().configToMap(),
        // 'mail': context.read<MailConfig>().toMap(),
        // 'auth': context.read<AuthConfig>().toMapDiff(AuthConfig.defaults()),
      },
      // 'user': context.read<UserConfig>().toMap(),
      'options': {
        // 'db': context.read<DbConfig>().optionsToMap()
      },
    };

    request.body = jsonEncode(data);

    final responseString = await sendRequestDialog(
      context,
      request,
      message: 'Finalizing instance configuration',
    );
    if (responseString == null || !context.mounted) return;
    final responseMap = (jsonDecode(responseString) as Map)
        .cast<String, dynamic>();

    if (responseMap["success"]) {
      await showAlertDialog(context, title: 'Instance configured');
      if (!context.mounted) return;
      context.read<PhylumRouterDelegate>().go(const HomeRoute());
    } else {
      await showAlertDialog(
        context,
        title: 'Could not finalize instance configuration',
        message: responseMap.containsKey("details")
            ? "${responseMap["error"]} - ${responseMap['details']}"
            : responseMap['error'],
      );
    }
  }
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
