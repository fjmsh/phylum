import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:uri/uri.dart';

import 'oauth_stub.dart' if (dart.library.js_interop) 'oauth_web.dart' if (dart.library.ffi) 'oauth_vm.dart';

class PasswordLoginFragment extends StatefulWidget {
  final Function()? onBackPressed;
  final Uri instanceUrl;
  final Function(String, String)? requestLogin;
  final Function(String)? requestPasswordReset;
  final Function(String, String)? resetPassword;
  final List<OpenIDProvider> openIDProviders;

  const PasswordLoginFragment({
    super.key,
    required this.onBackPressed,
    required this.instanceUrl,
    required this.requestLogin,
    required this.requestPasswordReset,
    required this.resetPassword,
    required this.openIDProviders,
  });

  @override
  State<PasswordLoginFragment> createState() => _PasswordLoginFragmentState();
}

class _PasswordLoginFragmentState extends State<PasswordLoginFragment> {
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        spacing: 12.0,
        children: [
          if (widget.requestLogin != null)
            TextField(
              decoration: const InputDecoration(
                label: Text('Email'),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: (value) => setState(() => _email = value.trim()),
            ),
          if (widget.requestLogin != null)
            TextField(
              decoration: const InputDecoration(
                label: Text('Password'),
              ),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.password],
              onChanged: (value) => setState(() => _password = value),
              onSubmitted: _email.isEmpty ? null : (value) => widget.requestLogin!(_email, _password),
            ),
          if (widget.requestPasswordReset != null)
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
                            widget.resetPassword!(_email, token);
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
                widget.requestPasswordReset!(_email);
              },
            ),
          ...widget.openIDProviders.map((p) => ElevatedButton(
              onPressed: () async {
                final builder = UriBuilder.fromUri(Uri.parse(p.endpoint));
                final redirectBuilder = UriBuilder.fromUri(widget.instanceUrl);
                redirectBuilder.path = '/login/oauth';
                builder.queryParameters['client_id'] = p.clientID;
                builder.queryParameters['response_type'] = 'code';
                builder.queryParameters['redirect_uri'] = redirectBuilder.toString();
                builder.queryParameters['scope'] = 'openid email profile';
                startOAuthFlow(builder.build());
              },
              child: Text('Log In with ${p.name}'))),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 12.0,
            children: [
              if (widget.onBackPressed != null)
                TextButton(
                  onPressed: widget.onBackPressed,
                  child: Text(
                    'Back',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (widget.requestLogin != null)
                ElevatedButton(
                  onPressed: _email.isEmpty || _password.isEmpty ? null : () => widget.requestLogin!(_email, _password),
                  child: Text('Login'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
