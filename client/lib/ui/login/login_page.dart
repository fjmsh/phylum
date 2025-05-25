import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/ui/login/password_login_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'request.dart';

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
      onSubmitted: (email, password) => _performLogin(context, instanceUrl, email, password),
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

        final contents = RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'This will request a password reset for $email.\n\nDo you want to continue?\n\n'),
              TextSpan(
                text: 'Tap here if you already have a reset token',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    final token = await showInputDialog(context, labelText: 'Reset Token', barrierDismissable: true);
                    if (token == null || !context.mounted) return;
                    Navigator.of(context).pop(false);
                    context
                        .read<PhylumRouterDelegate>()
                        .go(ResetPasswordRoute(instanceUri: instanceUrl, email: email, token: token));
                  },
              ),
            ],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
        final confirm = await showAlertDialog(
              context,
              title: 'Reset Password',
              contents: contents,
              negativeText: 'No',
              positiveText: 'Yes',
              barrierDismissible: true,
            ) ??
            false;
        if (!confirm || !context.mounted) return;
        _requestPasswordReset(context, instanceUrl, email);
      },
    );
  }

  Future<void> _performLogin(BuildContext context, Uri instanceUri, String email, String password) async {
    final builder = UriBuilder.fromUri(instanceUri);
    builder.path = '${builder.path}/api/v1/auth/password';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = email;
    request.fields['password'] = password;

    final responseString = await sendRequest(context, 'Logging In', request);
    if (responseString == null) return;
    if (context.mounted) {
      final accountManager = context.read<AccountManager<PhylumAccount>>();
      final navigator = Navigator.of(context);
      showProgressDialog(context, barrierDismissible: false, title: 'Processing Login Response');
      try {
        final response = jsonDecode(responseString) as Map;
        final account = await PhylumAccount.createFromLoginResponse(instanceUri, response.cast<String, dynamic>());
        accountManager.addAccount(account);
        navigator.pop();
      } catch (e) {
        navigator.pop();
        if (context.mounted) {
          showAlertDialog(
            context,
            barrierDismissible: false,
            title: 'Error',
            message: e.toString(),
          );
        }
      }
    }
  }

  Future<void> _requestPasswordReset(BuildContext context, Uri instanceUrl, String email) async {
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/request-password-reset';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = email;

    final responseString = await sendRequest(context, 'Requesting Password Reset', request);
    if (responseString == null) return;
    if (context.mounted) {
      await showAlertDialog(
        context,
        title: 'Password Reset Requested',
      );
    }
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
