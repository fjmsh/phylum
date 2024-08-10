import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:uri/uri.dart';

typedef AuthRequestBuilder = Future<Request?> Function(BuildContext, UriBuilder);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Client _client = Client();
  String _email = '';
  String _password = '';
  Uri? apiBase;
  String? urlError;
  String? emailError;

  bool get apiBaseValid => kIsWeb || (apiBase?.hasScheme == true && apiBase?.hasAuthority == true);

  @override
  void initState() {
    super.initState();
  }

  void _performLogin(BuildContext context, String email, String password) async {
    final apiBaseUrl = apiBase;
    if (!apiBaseValid) return;

    showProgressDialog(
      context,
      barrierDismissible: false,
      title: 'Logging in...',
    );
    final baseUri = apiBaseUrl == null ? UriBuilder() : UriBuilder.fromUri(apiBaseUrl);
    final path = baseUri.path.split('/').where((s) => s.isNotEmpty).join('/');
    baseUri.path = '$path/api/v1/auth/login';
    baseUri.queryParameters['username'] = email;
    baseUri.queryParameters['password'] = password;
    final request = Request('post', baseUri.build());

    try {
      final response = await _client.send(request);
      final responseString = await response.stream.bytesToString();
      final json = jsonDecode(responseString) as Map;

      if (context.mounted) {
        Navigator.of(context).pop();
        if (response.statusCode != 200) {
          showAlertDialog(
            context,
            barrierDismissible: false,
            title: 'Login Error',
            message: json['msg'],
          );
        } else {
          showAlertDialog(
            context,
            barrierDismissible: false,
            title: 'Login Successful',
            message: responseString,
          );
        }
      }
    } on SocketException {
      if (context.mounted) {
        Navigator.of(context).pop();
        showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Login Error',
          message: 'Unable to reach server',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Login Error',
          message: e.toString(),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (!kIsWeb)
                  TextField(
                    decoration: InputDecoration(
                      label: const Text('Server URL'),
                      hintText: 'http://localhost:1234/',
                      errorText: urlError,
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      setState(() {
                        apiBase = Uri.tryParse(value);
                        urlError = apiBase == null ? 'Invalid URL' : null;
                      });
                    },
                  ),
                TextField(
                  decoration: const InputDecoration(
                    label: Text('Username'),
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
                  onSubmitted: (value) {
                    _performLogin(context, _email, _password);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: apiBaseValid && _email.isNotEmpty
                        ? () async {
                            _performLogin(context, _email, _password);
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
    );
  }
}
