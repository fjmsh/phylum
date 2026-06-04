import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'instance_url.dart';
import 'login_controller.dart';
import 'login_request.dart';

class PasswordLogin extends StatefulWidget {
  const PasswordLogin({super.key});

  @override
  State<PasswordLogin> createState() => _PasswordLoginState();
}

class _PasswordLoginState extends State<PasswordLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _requestInFlight = false;

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
          LoginInstanceUrl(display: true),
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
                      label: Text(_requestInFlight ? 'Logging In' : 'Log In'),
                      icon: _requestInFlight
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: Center(
                                  child: CircularProgressIndicator(
                                strokeWidth: 2,
                              )),
                            )
                          : Icon(Icons.login),
                      onPressed: _requestInFlight ||
                              email.text.isEmpty ||
                              password.text.isEmpty
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
                  ..onTap = () => context
                          .read<LoginController>()
                          .selectedMethod = ResetPasswordMethod(
                        email: _emailController.text,
                        token: null,
                      ),
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
