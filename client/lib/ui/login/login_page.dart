import 'package:flutter/material.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/ui/login/password_login_fragment.dart';

import 'login_request.dart';

class LoginPage extends StatefulWidget {
  final Uri? fixedInstanceUrl;

  const LoginPage({super.key, this.fixedInstanceUrl});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Uri? _instanceUrl;

  @override
  void initState() {
    super.initState();
    _instanceUrl = widget.fixedInstanceUrl;
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
    final instanceUrl = _instanceUrl;
    if (instanceUrl == null) {
      return InstanceUrlFragment(onSubmitted: (url) => setState(() => _instanceUrl = url));
    }
    return PasswordLoginFragment(onSubmitted: (email, password) => performLogin(context, instanceUrl, email, password));
  }
}
