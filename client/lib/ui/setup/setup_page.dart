import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/setup/setup_auth_fragment.dart';
import 'package:phylum/ui/setup/setup_db_fragment.dart';
import 'package:phylum/ui/setup/setup_mail_fragment.dart';
import 'package:phylum/ui/setup/setup_user_fragment.dart';
import 'package:provider/provider.dart';

enum SetupStep {
  database,
  mail,
  auth,
  user;
}

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
        StateNotifierProvider<DbController, DbConfig>(create: (_) => DbController()),
        StateNotifierProvider<MailController, MailConfig>(create: (_) => MailController()),
        StateNotifierProvider<AuthController, AuthConfig>(create: (_) => AuthController()),
        StateNotifierProvider<UserController, UserConfig>(create: (_) => UserController()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Instance Setup'),
          leading: _currentStep.index == 0
              ? CloseButton(onPressed: () => context.read<PhylumRouterDelegate>().go(const ExplorerRouteHome()))
              : BackButton(onPressed: () => setState(() => _currentStep = SetupStep.values[_currentStep.index - 1])),
          actions: [
            _currentStep.index == SetupStep.values.length - 1
                ? TextButton(onPressed: () {}, child: Text('FINISH'))
                : Builder(builder: (context) {
                    return TextButton(onPressed: currentStepValid(context) ? nextStep : null, child: Text('NEXT'));
                  })
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_currentStep) {
      SetupStep.database => SetupDbFragment(instanceUrl: widget.instanceUrl),
      SetupStep.mail => SetupMailFragment(instanceUrl: widget.instanceUrl),
      SetupStep.auth => SetupAuthFragment(instanceUrl: widget.instanceUrl),
      SetupStep.user => SetupUserFragment(instanceUrl: widget.instanceUrl),
    };
  }

  bool currentStepValid(BuildContext context) {
    return switch (_currentStep) {
      SetupStep.database => true,
      SetupStep.mail => true,
      SetupStep.auth => context.select<AuthConfig, bool>((config) => config.valid),
      SetupStep.user => context.select<UserConfig, bool>((config) => config.password != '') ||
          !context.select<AuthConfig, bool>((config) => config.passwordConfig?.cryptConfig != null),
    };
  }

  void nextStep() {
    setState(() {
      _currentStep = SetupStep.values[_currentStep.index + 1];
    });
  }
}
