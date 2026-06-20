import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/layout/responsive.dart';
import 'package:phylum/ui/setup/auth/setup_auth_fragment.dart';
import 'package:phylum/ui/setup/setup_db_fragment.dart';
import 'package:phylum/ui/setup/setup_mail_fragment.dart';
import 'package:phylum/ui/setup/setup_user_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'auth/controller.dart';

enum SetupStep { database, mail, auth, user }

class SetupPage extends StatefulWidget {
  final String instanceUrl;

  const SetupPage({super.key, required this.instanceUrl});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  SetupStep _currentStep = SetupStep.database;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<DbController, DbConfig>(
          create: (_) => DbController(),
        ),
        StateNotifierProvider<MailController, MailConfig>(
          create: (_) => MailController(),
        ),
        StateNotifierProvider<AuthController, AuthConfig>(
          create: (_) => AuthController(),
        ),
        StateNotifierProvider<UserController, UserConfig>(
          create: (_) => UserController(),
        ),
      ],
      child: Scaffold(
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
              context.read<PhylumRouterDelegate>().go(HomeRouteConfig());
            },
          ),
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final page = switch (_currentStep) {
      SetupStep.database => SetupDbFragment(
        instanceUrl: widget.instanceUrl,
        onNextPress: nextStep,
      ),
      SetupStep.mail => SetupMailFragment(
        instanceUrl: widget.instanceUrl,
        onPrevPress: previousStep,
        onNextPress: nextStep,
      ),
      SetupStep.auth => SetupAuthFragment(
        instanceUrl: widget.instanceUrl,
        onPrevPress: previousStep,
        onNextPress: nextStep,
      ),
      SetupStep.user => SetupUserFragment(
        instanceUrl: widget.instanceUrl,
        onPrevPress: previousStep,
        onFinish: finalize,
      ),
    };

    if (MediaQuery.sizeOf(context).width > maxViewportWidthSmall) {
      return Center(child: SizedBox(width: 640, child: page));
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: page);
  }

  void nextStep() {
    setState(() {
      _currentStep = SetupStep.values[_currentStep.index + 1];
    });
  }

  void previousStep() {
    setState(() {
      _currentStep = SetupStep.values[_currentStep.index - 1];
    });
  }

  void finalize(BuildContext context) async {
    final builder = UriBuilder.fromUri(Uri.parse(widget.instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/finalize';
    final request = Request('post', builder.build());
    final data = {
      'config': {
        'db': context.read<DbConfig>().toMap(),
        'mail': context.read<MailConfig>().toMap(),
        'auth': context.read<AuthConfig>().toMap(),
      },
      'user': context.read<UserConfig>().toMap(),
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
      context.read<PhylumRouterDelegate>().go(
        ExplorerRoute(location: ExplorerLocationHome()),
      );
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
