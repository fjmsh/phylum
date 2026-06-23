import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/instance_url.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:phylum/ui/login/login_email.dart';
import 'package:phylum/ui/login/login_selector.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

  static Widget create({
    Uri? instanceUrl,
    LoginMethod? method,
    String? email,
    String? token,
  }) {
    return StateNotifierProvider<LoginController, LoginState>(
      create: (_) => LoginController(
        LoginState.create(instanceUrl: instanceUrl, selectedMethod: method),
      ),
      child: LoginPage(),
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
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
      return const LoginInstanceUrl(display: false);
    }

    final authConfig = state.instanceInfo!.authConfig!;
    if (authConfig.openIDProviders.isEmpty) {
      return const EmailLogin();
    }
    return const LoginSelector();
  }
}
