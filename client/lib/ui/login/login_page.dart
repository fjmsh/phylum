import 'package:flutter/material.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/ui/login/login_fragment.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  InstanceInfo? _instanceInfo;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: LogoRow(),
                  ),
                  _buildBody(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final instanceConfig = _instanceInfo;
    if (instanceConfig == null) {
      return InstanceUrlFragment(onInstanceSelected: (instanceConfig) {
        setState(() => _instanceInfo = instanceConfig);
      });
    }
    return LoginFragment(
      onBackPressed: () => setState(() => _instanceInfo = null),
      instanceInfo: instanceConfig,
    );
  }
}
