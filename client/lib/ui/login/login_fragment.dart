import 'dart:convert';

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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            ListTile(
              visualDensity: VisualDensity.compact,
              dense: true,
              title: Text(widget.instanceConfig.url.toString()),
              leading: Icon(Icons.storage),
              trailing: IconButton(onPressed: widget.onBackPressed, icon: Icon(Icons.close)),
            ),
            if (widget.instanceConfig.email)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(label: Text('Email')),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      onChanged: (value) => setState(() => _email = value.trim()),
                    ),
                  ),
                  if (widget.instanceConfig.magicLinks)
                    IconButton(
                      icon: Icon(
                        Icons.link,
                        semanticLabel: 'Request Login Link',
                      ),
                      onPressed: () async {
                        _requestMagicLink(context, widget.instanceConfig.url, _email);
                      },
                    ),
                ],
              ),
            if (widget.instanceConfig.password)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(label: Text('Password')),
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      autofillHints: const [AutofillHints.password],
                      onChanged: (value) => setState(() => _password = value),
                      onSubmitted: _email.isEmpty
                          ? null
                          : (value) => _performLogin(context, widget.instanceConfig.url, _email, _password),
                    ),
                  ),
                  if (widget.instanceConfig.passwordReset)
                    IconButton(
                      icon: Icon(
                        Icons.question_mark,
                        semanticLabel: 'Request password reset',
                      ),
                      onPressed: () async {
                        _requestPasswordReset(context, widget.instanceConfig.url, _email);
                      },
                    ),
                  IconButton(
                    onPressed: _email.isEmpty || _password.isEmpty
                        ? null
                        : () => _performLogin(context, widget.instanceConfig.url, _email, _password),
                    icon: Icon(
                      Icons.login,
                      semanticLabel: 'Log in with password',
                    ),
                  ),
                ],
              ),
            if (widget.instanceConfig.email && widget.instanceConfig.openIDProviders.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12, left: 48, right: 48),
                child: Divider(),
              ),
            ...widget.instanceConfig.openIDProviders.map((p) => Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextButton(
                      onPressed: () async {
                        final builder = UriBuilder.fromUri(widget.instanceConfig.url);
                        builder.path += '/api/v1/auth/oauth/start';
                        builder.queryParameters['provider'] = p.id;
                        startOAuthFlow(context, builder, p.name);
                      },
                      child: Text('Log In with ${p.name}')),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogin(BuildContext context, Uri instanceUri, String email, String password) async {
    final builder = UriBuilder.fromUri(instanceUri);
    builder.path = '${builder.path}/api/v1/auth/password/login';
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

  Future<void> _requestMagicLink(BuildContext context, Uri instanceUrl, String? email) async {
    email = await showInputDialog(
      context,
      title: 'Login Link',
      labelText: 'Email',
      hintText: 'user@example.com',
      preset: email,
      maxLines: 1,
      keyboardType: TextInputType.emailAddress,
    );
    if (email == null || !context.mounted) {
      return;
    }

    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/request';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = email;

    final responseString = await sendRequest(context, 'Requesting Login Link', request);
    if (responseString == null) return;
    if (context.mounted) {
      final response = await showAlertDialog(
        context,
        title: 'Login Link Sent',
        message: 'Please check your email for a login link',
        negativeText: 'Enter Manually',
        colorNegative: false,
      );

      if ((response ?? true) || !context.mounted) return;

      context.read<PhylumRouterDelegate>().go(TokenLoginRoute(
            instanceUrl: widget.instanceConfig.url.toString(),
          ));
    }
  }

  Future<void> _requestPasswordReset(BuildContext context, Uri instanceUrl, String? email) async {
    email = await showInputDialog(
      context,
      title: 'Password Reset',
      labelText: 'Email',
      hintText: 'user@example.com',
      preset: email,
      maxLines: 1,
      keyboardType: TextInputType.emailAddress,
    );
    if (email == null || !context.mounted) {
      return;
    }

    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/request-reset';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = email;

    final responseString = await sendRequest(context, 'Requesting Password Reset', request);
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

      final token = await showInputDialog(context, title: 'Password Reset Token', barrierDismissable: true);
      if (token == null || !context.mounted) return;
      context.read<PhylumRouterDelegate>().go(ResetPasswordRoute(
            instanceUrl: widget.instanceConfig.url.toString(),
            email: email,
            token: token,
          ));
    }
  }
}
