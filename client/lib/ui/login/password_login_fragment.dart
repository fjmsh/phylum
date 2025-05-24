import 'package:flutter/material.dart';

class PasswordLoginFragment extends StatefulWidget {
  final Function(String, String) onSubmitted;

  const PasswordLoginFragment({super.key, required this.onSubmitted});

  @override
  State<PasswordLoginFragment> createState() => _PasswordLoginFragmentState();
}

class _PasswordLoginFragmentState extends State<PasswordLoginFragment> {
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Column(
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
          onSubmitted: _email.isNotEmpty ? (value) => widget.onSubmitted(_email, _password) : null,
        ),
        TextButton(onPressed: () {}, child: Text('Forgot Password')),
        ElevatedButton(
          onPressed: _email.isEmpty || _password.isEmpty ? null : () => widget.onSubmitted(_email, _password),
          child: Text('Login'),
        )
      ],
    );
  }
}
