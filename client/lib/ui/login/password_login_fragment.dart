import 'package:flutter/material.dart';

class PasswordLoginFragment extends StatefulWidget {
  final Function(String, String) onSubmitted;
  final Function()? onBackPressed;
  final Function(String) onForgotPassword;

  const PasswordLoginFragment({
    super.key,
    required this.onSubmitted,
    required this.onBackPressed,
    required this.onForgotPassword,
  });

  @override
  State<PasswordLoginFragment> createState() => _PasswordLoginFragmentState();
}

class _PasswordLoginFragmentState extends State<PasswordLoginFragment> {
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12.0,
      children: [
        TextField(
          decoration: const InputDecoration(
            label: Text('Email'),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => setState(() => _email = value.trim()),
        ),
        TextField(
          decoration: const InputDecoration(
            label: Text('Password'),
          ),
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (value) => setState(() => _password = value),
          onSubmitted: _email.isEmpty ? null : (value) => widget.onSubmitted(_email, _password),
        ),
        TextButton(
            onPressed: () => widget.onForgotPassword(_email),
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
              onPressed: _email.isEmpty || _password.isEmpty ? null : () => widget.onSubmitted(_email, _password),
              child: Text('Login'),
            ),
          ],
        ),
      ],
    );
  }
}
