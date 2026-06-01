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
import 'package:phylum/util/request.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'oauth_stub.dart'
    if (dart.library.js_interop) 'oauth_web.dart'
    if (dart.library.ffi) 'oauth_vm.dart';

class LoginFragment extends StatefulWidget {
  final InstanceInfo instanceInfo;
  final Function()? onBackPressed;

  const LoginFragment({
    super.key,
    required this.instanceInfo,
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
    return ElevatedButtonTheme(
        data: ElevatedButtonThemeData(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            TextFormField(
              decoration: InputDecoration(
                label: const Text('Instance URL'),
                prefixIcon: Icon(Icons.storage),
                suffixIcon: IconButton(
                  onPressed: widget.onBackPressed,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.edit),
                  iconSize: 18,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
              initialValue: widget.instanceInfo.url.toString(),
              keyboardType: TextInputType.url,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 48, right: 48),
              child: Divider(),
            ),
            buildPage(context),
          ],
        ));
  }

  Widget buildPage(BuildContext context) {
    final authConfig = widget.instanceInfo.authConfig!;
    if (authConfig.password &&
        !authConfig.magicLinks &&
        authConfig.openIDProviders.isEmpty) {
      return buildPasswordLogin(context, authConfig);
    } else if (authConfig.magicLinks &&
        !authConfig.password &&
        authConfig.openIDProviders.isEmpty) {
      return buildMagicLinkLogin(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (authConfig.password)
          ElevatedButton.icon(
            onPressed: () async {},
            icon: Icon(Icons.password),
            label: Text('Password'),
          ),
        if (authConfig.magicLinks)
          ElevatedButton.icon(
            onPressed: () async {},
            icon: Icon(Icons.email),
            label: Text('Email'),
          ),
        ...authConfig.openIDProviders.map((p) => ElevatedButton(
            onPressed: () async {
              final builder = UriBuilder.fromUri(widget.instanceInfo.url);
              builder.path += '/api/v1/auth/oauth/start';
              builder.queryParameters['provider'] = p.id;
              startOAuthFlow(context, builder, p.name);
            },
            child: Text(p.name))),
      ],
    );
  }

  Widget buildPasswordLogin(BuildContext context, AuthConfig authConfig) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          TextField(
            decoration: const InputDecoration(
              label: Text('Email'),
              prefixIcon: Icon(Icons.email),
            ),
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (value) => setState(() => _email = value.trim()),
          ),
          TextField(
            decoration: const InputDecoration(
              label: Text('Password'),
              prefixIcon: Icon(Icons.password),
            ),
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            onChanged: (value) => setState(() => _password = value),
            onSubmitted: _email.isEmpty
                ? null
                : (value) => _performLogin(
                    context, widget.instanceInfo.url, _email, _password),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            ),
            label: Text('Login'),
            icon: Icon(Icons.login),
            onPressed: _email.isEmpty || _password.isEmpty
                ? null
                : () => _performLogin(
                    context, widget.instanceInfo.url, _email, _password),
          ),
          if (authConfig.passwordReset)
            Center(
              child: Text.rich(TextSpan(
                text: 'Forgot Password',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _requestPasswordReset(
                      context, widget.instanceInfo.url, _email),
              )),
            ),
        ],
      ),
    );
  }

  Widget buildMagicLinkLogin(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          TextField(
            decoration: const InputDecoration(
              label: Text('Email'),
              prefixIcon: Icon(Icons.email),
            ),
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (value) => setState(() => _email = value.trim()),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 18),
            ),
            label: Text('Request Email Login Link'),
            icon: Icon(Icons.email),
            onPressed: _email.isEmpty
                ? null
                : () =>
                    _requestMagicLink(context, widget.instanceInfo.url, _email),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogin(BuildContext context, Uri instanceUri,
      String email, String password) async {
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
      showProgressDialog(context,
          barrierDismissible: false, message: 'Logging In');
      try {
        final response = BootstrapLoginResponse.fromResponse(
            (jsonDecode(responseString) as Map).cast<String, dynamic>());
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

  Future<void> _requestMagicLink(
    BuildContext context,
    Uri instanceUrl,
    String? email,
  ) async {
    if (email == null) {
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
    }

    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/request';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = email;

    final responseString =
        await sendRequest(context, 'Requesting Login Link', request);
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
            instanceUrl: widget.instanceInfo.url.toString(),
          ));
    }
  }

  Future<void> _requestPasswordReset(
      BuildContext context, Uri instanceUrl, String? email) async {
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

      final token = await showInputDialog(context,
          title: 'Password Reset Token', barrierDismissable: true);
      if (token == null || !context.mounted) return;
      context.read<PhylumRouterDelegate>().go(ResetPasswordRoute(
            instanceUrl: widget.instanceInfo.url.toString(),
            email: email,
            token: token,
          ));
    }
  }
}
