import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:phylum/ui/login/login_selector.dart';
import 'package:phylum/ui/login/login_magic_link.dart';
import 'package:phylum/ui/login/login_password.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

  static Widget create() {
    return StateNotifierProvider<LoginController, LoginState>(
      create: (_) => LoginController(),
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
                          vertical: 18, horizontal: 24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 24.0,
                  children: <Widget>[
                    LogoRow(),
                    _buildBody(context),
                  ],
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
    final instanceInfo = state.instanceInfo;
    if (instanceInfo == null) {
      return const InstanceUrlFragment();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        TextFormField(
          key: ValueKey('instanceUrl'),
          decoration: InputDecoration(
            label: const Text('Instance URL'),
            prefixIcon: Icon(Icons.storage),
            suffixIcon: IconButton(
              onPressed: () => context.read<LoginController>().reset(),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.edit),
              iconSize: 18,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          initialValue: state.instanceUrl?.toString(),
          keyboardType: TextInputType.url,
        ),
        const Padding(
          padding: EdgeInsets.only(left: 48, right: 48),
          child: Divider(),
        ),
        buildPage(context, state),
      ],
    );
  }

  Widget buildPage(BuildContext context, LoginState state) {
    final authConfig = state.instanceInfo!.authConfig!;
    if (state.selectedMethod == LoginMethod.password ||
        (authConfig.password &&
            !authConfig.magicLinks &&
            authConfig.openIDProviders.isEmpty)) {
      return PasswordLogin();
    } else if (state.selectedMethod == LoginMethod.magicLink ||
        (authConfig.magicLinks &&
            !authConfig.password &&
            authConfig.openIDProviders.isEmpty)) {
      return MagicLinkLogin();
    }
    return const LoginSelector();
  }
}
