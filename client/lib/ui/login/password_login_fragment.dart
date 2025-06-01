import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phylum/util/dialogs.dart';

class PasswordLoginFragment extends StatefulWidget {
  final Function(String, String) requestLogin;
  final Function()? onBackPressed;
  final Function(String) requestPasswordReset;
  final Function(String, String) resetPassword;

  const PasswordLoginFragment({
    super.key,
    required this.requestLogin,
    required this.onBackPressed,
    required this.requestPasswordReset,
    required this.resetPassword,
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
          TextField(
            decoration: const InputDecoration(
              label: Text('Email'),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (value) => setState(() => _email = value.trim()),
          ),
          TextField(
            decoration: const InputDecoration(
              label: Text('Password'),
            ),
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            onChanged: (value) => setState(() => _password = value),
            onSubmitted: _email.isEmpty ? null : (value) => widget.requestLogin(_email, _password),
          ),
          TextButton(
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
                            widget.resetPassword(_email, token);
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
                widget.requestPasswordReset(_email);
              },
              child: Text(
                'Forgot Password',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              )),
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
              ElevatedButton(
                onPressed: _email.isEmpty || _password.isEmpty ? null : () => widget.requestLogin(_email, _password),
                child: Text('Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
