import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/instance_url_field.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'login_controller.dart';
import 'login_request.dart';

class EmailLogin extends StatefulWidget {
  const EmailLogin({super.key});

  @override
  State<EmailLogin> createState() => _EmailLoginState();
}

class _EmailLoginState extends State<EmailLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _forcePassword = false;
  bool _requestInFlight = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authConfig = context.read<LoginState>().instanceInfo?.authConfig;
    bool magicLinkLogin = authConfig?.magicLinks != false && !_forcePassword;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          const InstanceUrlField(),
          if (magicLinkLogin)
            buildMagicLinkLogin(context, authConfig)
          else
            buildPasswordLogin(context, authConfig),
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

  Widget buildMagicLinkLogin(BuildContext context, AuthConfig? authConfig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
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
          onSubmitted: _requestInFlight
              ? null
              : (value) => value.isEmpty ? null : _requestMagicLink(context),
        ),
        ValueListenableBuilder(
          valueListenable: _emailController,
          builder: (_, email, __) => ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text(
              _requestInFlight ? 'Requesting Login Link' : 'Request Login Link',
            ),
            icon: _requestInFlight
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(Icons.email),
            onPressed: _requestInFlight || email.text.isEmpty
                ? null
                : () => _requestMagicLink(context),
          ),
        ),
        if (authConfig?.password != false)
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Enter Password',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => setState(() => _forcePassword = true),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildPasswordLogin(BuildContext context, AuthConfig? authConfig) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
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
            onSubmitted: _requestInFlight
                ? null
                : (value) => value.isEmpty ? null : _performLogin(context),
          ),
          ValueListenableBuilder(
            valueListenable: _emailController,
            builder: (_, email, __) => ValueListenableBuilder(
              valueListenable: _passwordController,
              builder: (_, password, __) => ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                label: Text(_requestInFlight ? 'Logging In' : 'Log In'),
                icon: _requestInFlight
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(Icons.login),
                onPressed:
                    _requestInFlight ||
                        email.text.isEmpty ||
                        password.text.isEmpty
                    ? null
                    : () => _performLogin(context),
              ),
            ),
          ),
          if (authConfig?.passwordReset != false)
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Forgot Password',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () =>
                        context
                            .read<LoginController>()
                            .selectedMethod = ResetPasswordMethod(
                          email: _emailController.text,
                          token: null,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _requestMagicLink(BuildContext context) async {
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/request';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;

    setState(() => _requestInFlight = true);
    final result = await sendRequest(request);
    setState(() => _requestInFlight = false);
    if (!context.mounted) return;
    if (result is! SuccessResponse) {
      final message = result.details == null
          ? result.title
          : '${result.title} - ${result.details}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    context.read<LoginController>().selectedMethod = TokenLoginMethod(null);
  }

  Future<void> _performLogin(BuildContext context) async {
    if (_requestInFlight) return;
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/login';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;
    request.fields['password'] = _passwordController.text;

    setState(() => _requestInFlight = true);
    await login(context, request);
    setState(() => _requestInFlight = false);
  }
}
