import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/request.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'oauth_stub.dart' if (dart.library.js_interop) 'oauth_web.dart' if (dart.library.ffi) 'oauth_vm.dart';

class LoginFragment extends StatefulWidget {
  final InstanceConfig instanceConfig;
  final Function()? onBackPressed;

  const LoginFragment({
    super.key,
    required this.instanceConfig,
    required this.onBackPressed,
  });

  @override
  State<LoginFragment> createState() => _LoginFragmentState();
}

class _LoginFragmentState extends State<LoginFragment> {
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        spacing: 12.0,
        children: [
          ListTile(
            title: Text(widget.instanceConfig.url.toString()),
            trailing: IconButton(onPressed: widget.onBackPressed, icon: Icon(Icons.edit)),
          ),
          if (widget.instanceConfig.hasEmailLogin)
            TextField(
              decoration: const InputDecoration(
                label: Text('Email'),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: (value) => setState(() => _email = value.trim()),
            ),
          if (widget.instanceConfig.password)
            TextField(
              decoration: const InputDecoration(
                label: Text('Password'),
              ),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.password],
              onChanged: (value) => setState(() => _password = value),
              onSubmitted: _email.isEmpty
                  ? null
                  : (value) => _performLogin(context, widget.instanceConfig.url, _email, _password),
            ),
          ElevatedButton(
            onPressed: _email.isEmpty || _password.isEmpty
                ? null
                : () => _performLogin(context, widget.instanceConfig.url, _email, _password),
            child: Text('Login'),
          ),
          if (widget.instanceConfig.passwordReset)
            TextButton(
              child: Text('Reset Password', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () async {
                if (_email.isEmpty) {
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
                      TextSpan(text: 'This will request a password reset for $_email.\n\nDo you want to continue?\n\n'),
                      TextSpan(
                        text: 'Tap here if you already have a reset token',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final token =
                                await showInputDialog(context, labelText: 'Reset Token', barrierDismissable: true);
                            if (token == null || !context.mounted) return;
                            Navigator.of(context).pop(false);
                            context.read<PhylumRouterDelegate>().go(ResetPasswordRoute(
                                  instanceUrl: widget.instanceConfig.url.toString(),
                                  email: _email,
                                  token: token,
                                ));
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
                _requestPasswordReset(context, widget.instanceConfig.url, _email);
              },
            ),
          ...widget.instanceConfig.openIDProviers.map((p) => ElevatedButton(
              onPressed: () async {
                final builder = UriBuilder.fromUri(widget.instanceConfig.url);
                builder.path += '/api/v1/auth/oauth/start';
                builder.queryParameters['provider'] = p.id;
                showProgressDialog(context, barrierDismissible: false, message: 'Logging in with ${p.name}...');
                startOAuthFlow(builder);
              },
              child: Text('Log In with ${p.name}'))),
        ],
      ),
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
      showProgressDialog(context, barrierDismissible: false, message: 'Logging In');
      try {
        final response =
            BootstrapLoginResponse.fromResponse((jsonDecode(responseString) as Map).cast<String, dynamic>());
        final account = await PhylumAccount.create(
          serverUrl: instanceUri,
          apiKey: response.apiKey!,
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
}
