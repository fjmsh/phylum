import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/common/logo_row.dart';

import 'login_request.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email = '';
  String _password = '';
  Uri? serverUrl = kIsWeb ? Uri() : null;
  String? urlError;
  String? emailError;

  bool get serverUrlValid =>
      (kIsWeb && serverUrl == Uri()) || (serverUrl?.hasScheme == true && serverUrl?.hasAuthority == true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: LogoRow(),
                  ),
                  if (kDebugMode || !kIsWeb)
                    TextField(
                      decoration: InputDecoration(
                        label: const Text('Server URL'),
                        hintText: 'http://localhost:2448/',
                        errorText: urlError,
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (value) {
                        setState(() {
                          serverUrl = kIsWeb && value == '' ? Uri() : Uri.tryParse(value);
                          urlError = serverUrl == null ? 'Invalid URL' : null;
                        });
                      },
                    ),
                  TextField(
                    decoration: const InputDecoration(
                      label: Text('Email'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setState(() {
                        _email = value.trim();
                      });
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      label: Text('Password'),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (value) {
                      setState(() {
                        _password = value.trim();
                      });
                    },
                    onSubmitted: serverUrlValid
                        ? (value) {
                            performLogin(context, serverUrl ?? Uri(), _email, _password);
                          }
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: serverUrlValid && _email.isNotEmpty
                          ? () async {
                              performLogin(context, serverUrl ?? Uri(), _email, _password);
                            }
                          : null,
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
