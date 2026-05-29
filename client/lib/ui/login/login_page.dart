import 'package:flutter/material.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/ui/login/login_fragment.dart';
import 'package:provider/provider.dart';

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
              padding: const EdgeInsets.all(24.0),
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
    );
  }

  Widget _buildBody(BuildContext context) {
    final instanceConfig = _instanceInfo;
    if (instanceConfig == null) {
      final delegate = context.read<PhylumRouterDelegate>();
      return InstanceUrlFragment(onInstanceSelected: (instanceInfo) {
        if (instanceInfo.needsSetup) {
          delegate.go(SetupRoute(
            instanceUrl: instanceInfo.url.toString(),
          ));
        } else {
          setState(() => _instanceInfo = instanceInfo);
        }
      });
    }
    return LoginFragment(
      onBackPressed: () => setState(() => _instanceInfo = null),
      instanceInfo: instanceConfig,
    );
  }
}
