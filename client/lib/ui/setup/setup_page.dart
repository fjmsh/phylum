import 'package:flutter/material.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/setup/setup_auth_fragment.dart';
import 'package:phylum/ui/setup/setup_db_fragment.dart';
import 'package:phylum/ui/setup/setup_fragment.dart';
import 'package:phylum/ui/setup/setup_mail_fragment.dart';
import 'package:provider/provider.dart';

enum SetupState {
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
  SetupState _currentState = SetupState.database;

  final dbFragmentKey = GlobalKey<SetupDbFragmentState>();
  final dbConfig = DbConfig();

  final mailFragmentKey = GlobalKey<SetupMailFragmentState>();
  final mailConfig = MailConfig();

  final authFragmentKey = GlobalKey<SetupAuthFragmentState>();
  AuthConfig authConfig = const AuthConfig.defaults();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instance Setup'),
        leading: _currentState.index == 0
            ? CloseButton(onPressed: () => context.read<PhylumRouterDelegate>().go(const ExplorerRouteHome()))
            : BackButton(onPressed: () => setState(() => _currentState = SetupState.values[_currentState.index - 1])),
        actions: [
          _currentState.index == SetupState.values.length - 1
              ? TextButton(onPressed: () {}, child: Text('FINISH'))
              : TextButton(onPressed: handleNextPress, child: Text('NEXT'))
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_currentState) {
      SetupState.database => SetupDbFragment(
          key: dbFragmentKey,
          instanceUrl: widget.instanceUrl,
          config: dbConfig,
        ),
      SetupState.mail => SetupMailFragment(
          key: mailFragmentKey,
          instanceUrl: widget.instanceUrl,
          config: mailConfig,
        ),
      SetupState.auth => SetupAuthFragment(
          key: authFragmentKey,
          instanceUrl: widget.instanceUrl,
          config: authConfig,
          mailEnabled: mailConfig.enabled,
        ),
      SetupState.user => throw UnimplementedError(),
    };
  }

  void updateAuthConfig(AuthConfig config) {
    authConfig = config;
  }

  void handleNextPress() {
    final GlobalKey<SetupFragmentState> currentKey = switch (_currentState) {
      SetupState.database => dbFragmentKey,
      SetupState.mail => mailFragmentKey,
      SetupState.auth => authFragmentKey,
      SetupState.user => throw UnimplementedError(),
    };
    if (currentKey.currentState?.handleNextPress() ?? false) {
      setState(() {
        _currentState = SetupState.values[_currentState.index + 1];
      });
    }
  }
}
