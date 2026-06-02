import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'login_controller.dart';

class PasswordLogin extends StatefulWidget {
  const PasswordLogin({super.key});

  @override
  State<PasswordLogin> createState() => _PasswordLoginState();
}

class _PasswordLoginState extends State<PasswordLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          const InstanceUrlFragment(readonly: true),
          TextField(
            key: ValueKey('email'),
            decoration: const InputDecoration(
              label: Text('Email'),
              prefixIcon: Icon(Icons.email),
            ),
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          TextField(
            key: ValueKey('password'),
            decoration: const InputDecoration(
              label: Text('Password'),
              prefixIcon: Icon(Icons.password),
            ),
            obscureText: true,
            controller: _passwordController,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            onSubmitted: _emailController.text.isEmpty
                ? null
                : (value) => _performLogin(context),
          ),
          ValueListenableBuilder(
              valueListenable: _emailController,
              builder: (_, email, __) => ValueListenableBuilder(
                    valueListenable: _passwordController,
                    builder: (_, password, __) => ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      label: Text('Login'),
                      icon: Icon(Icons.login),
                      onPressed: email.text.isEmpty || password.text.isEmpty
                          ? null
                          : () => _performLogin(context),
                    ),
                  )),
          if (context
                  .read<LoginState>()
                  .instanceInfo
                  ?.authConfig
                  ?.passwordReset ==
              true)
            Center(
              child: Text.rich(TextSpan(
                text: 'Forgot Password',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _requestReset(context),
              )),
            ),
          if (context.read<LoginState>().selectedMethod != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              label: Text('Back'),
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                context.read<LoginController>().selectedMethod = null;
              },
            ),
        ],
      ),
    );
  }

  Future<void> _performLogin(BuildContext context) async {
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/login';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;
    request.fields['password'] = _passwordController.text;

    final responseString = await sendRequest(context, 'Logging In', request);
    if (responseString == null) return;
    if (context.mounted) {
      final accountManager = context.read<AccountManager<PhylumAccount>>();
      final navigator = Navigator.of(context);
      showProgressDialog(context,
          barrierDismissible: false, message: 'Logging In');
      try {
        final response = BootstrapLoginResponse.fromResponse(
            (jsonDecode(responseString) as Map).cast<String, dynamic>());
        final account = await PhylumAccount.create(
          serverUrl: instanceUrl,
          apiToken: response.apiToken!,
          user: response.user,
        );
        await response.process(account);
        await accountManager.addAccount(account);
        navigator.pop();
      } catch (e, stack) {
        navigator.pop();
        if (context.mounted) {
          showAlertDialog(
            context,
            barrierDismissible: false,
            title: 'Error',
            message: e.toString(),
          );
        }
        logger.w('Login Error', error: e, stackTrace: stack);
      }
    }
  }

  Future<void> _requestReset(BuildContext context) async {
    final instanceUrl = context.read<LoginState>().instanceInfo!.url;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/request-reset';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;

    final responseString =
        await sendRequest(context, 'Requesting Password Reset', request);
    if (responseString == null) return;
    if (context.mounted) {
      final response = await showAlertDialog(
        context,
        title: 'Password Reset Requested',
        message: 'Please check your email for a password reset link',
        negativeText: 'Enter Manually',
        colorNegative: false,
      );

      if ((response ?? true) || !context.mounted) return;

      final token = await showInputDialog(
        context,
        title: 'Password Reset Token',
        barrierDismissable: true,
      );
      if (token == null || !context.mounted) return;
      context.read<PhylumRouterDelegate>().go(ResetPasswordRoute(
            instance: instanceUrl.toString(),
            email: _emailController.text,
            token: token,
          ));
    }
  }
}
