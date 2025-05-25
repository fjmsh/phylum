import 'package:flutter/material.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/ui/login/password_login_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:uri/uri.dart';

import 'requests.dart';

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
    if (widget.fixedInstanceUrl != null) {
      _instanceUrl = _cleanUrl(widget.fixedInstanceUrl!);
    }
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
      return InstanceUrlFragment(onSubmitted: (url) {
        setState(() => _instanceUrl = _cleanUrl(url));
      });
    }
    return PasswordLoginFragment(
      onSubmitted: (email, password) => performLogin(context, instanceUrl, email, password),
      onBackPressed: widget.fixedInstanceUrl == null ? () => setState(() => _instanceUrl = null) : null,
      onForgotPassword: (email) async {
        if (email.isEmpty) {
          showAlertDialog(
            context,
            message: 'Please enter email address to reset password',
            barrierDismissible: true,
          );
          return;
        }
        final confirm = await showAlertDialog(
              context,
              title: 'Reset Password',
              message: 'This will request a password reset for $email. Do you want to continue?',
              negativeText: 'No',
              positiveText: 'Yes',
              barrierDismissible: true,
            ) ??
            false;
        if (!confirm || !context.mounted) return;
        requestPasswordReset(context, instanceUrl, email);
      },
    );
  }

  Uri _cleanUrl(Uri url) {
    if (url.path.endsWith('/')) {
      final builder = UriBuilder.fromUri(url);
      builder.path = url.pathSegments.where((s) => s.isNotEmpty).join('/');
      return builder.build();
    }
    return url;
  }
}
