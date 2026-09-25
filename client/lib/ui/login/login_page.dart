import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/screens/existing_login.dart';
import 'package:phylum/ui/login/screens/instance_url.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:phylum/ui/login/screens/email_login.dart';
import 'package:phylum/ui/login/screens/login_selector.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'util/oauth_stub.dart'
    if (dart.library.js_interop) 'util/oauth_web.dart'
    if (dart.library.ffi) 'util/oauth_vm.dart';

class LoginPage extends StatefulWidget {
  final Uri? instanceUri;
  final LoginMethod? selectedMethod;

  const LoginPage({super.key, this.instanceUri, this.selectedMethod});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _loginController;
  @override
  void initState() {
    super.initState();
    _loginController = LoginController(
      LoginState.create(
        instanceUrl: widget.instanceUri,
        selectedMethod: widget.selectedMethod,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    _loginController.reset(
      LoginState.create(
        instanceUrl: widget.instanceUri,
        selectedMethod: widget.selectedMethod,
      ),
    );
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StateNotifierProvider<LoginController, LoginState>.value(
      value: _loginController,
      builder: (context, child) => buildPage(context),
    );
  }

  Widget buildPage(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButtonTheme(
                data: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 24.0,
                    children: <Widget>[LogoRow(), _buildBody(context)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final accounts = context
        .select<AccountManagerState<PhylumAccount>, Map<String, PhylumAccount>>(
          (state) => state.accounts,
        );
    if (accounts.isNotEmpty) {
      return ExistingLoginScreen(accounts: accounts);
    }

    final state = context.watch<LoginState>();
    final instanceUrl = state.instanceUrl;
    if (instanceUrl != null &&
        instanceUrl.hasScheme &&
        instanceUrl.hasAuthority &&
        state.selectedMethod != null) {
      return state.selectedMethod!.build();
    }
    final instanceInfo = state.instanceInfo;
    if (instanceInfo == null) {
      return InstanceUrlScreen(
        onInstanceConnected: (info) {
          final authConfig = info.authConfig;
          if (authConfig == null) return;
          if (!authConfig.email && authConfig.openIDProviders.length == 1) {
            final builder = UriBuilder.fromUri(info.url);
            builder.path += '/api/v1/auth/oauth/start';
            final provider = authConfig.openIDProviders.first;
            builder.queryParameters['provider'] = provider.id;
            startOAuthFlow(context, builder, provider.name);
          }
        },
      );
    }

    final authConfig = instanceInfo.authConfig!;
    if (authConfig.openIDProviders.isEmpty) {
      return const EmailLoginScreen();
    }

    return const LoginSelectorScreen();
  }
}
