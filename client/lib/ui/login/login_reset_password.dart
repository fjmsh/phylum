import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'instance_url.dart';
import 'login_controller.dart';
import 'login_request.dart';

class ResetPasswordLogin extends StatefulWidget {
  final String? email;
  final String? token;

  const ResetPasswordLogin({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordLogin> createState() => _ResetPasswordLoginState();
}

class _ResetPasswordLoginState extends State<ResetPasswordLogin> {
  late final _emailController = TextEditingController(text: widget.email);
  late final _tokenController = TextEditingController(text: widget.token);
  late final _passwordController = TextEditingController();
  late bool _tokenRequested = widget.token?.isNotEmpty == true;
  bool _requestInFlight = false;
  bool passwordVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        const LoginInstanceUrl(),
        TextFormField(
          decoration: InputDecoration(label: Text('Email')),
          controller: _emailController,
          readOnly: _tokenRequested,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofocus: widget.token == null,
          textInputAction: _tokenRequested
              ? TextInputAction.next
              : TextInputAction.go,
          onFieldSubmitted: _requestInFlight || _tokenRequested
              ? null
              : (value) => _requestReset(context),
        ),
        if (_tokenRequested)
          TextField(
            decoration: InputDecoration(
              label: Text('Token'),
              hintText: 'AG...',
              suffixIcon: widget.token != null
                  ? null
                  : IconButton(
                      icon: Icon(Icons.paste),
                      onPressed: () async {
                        if (await Clipboard.hasStrings()) {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          final text = data?.text;
                          if (text != null) {
                            _tokenController.text = text;
                          }
                        }
                      },
                    ),
            ),
            controller: _tokenController,
            readOnly: widget.token != null,
            keyboardType: TextInputType.text,
            autocorrect: false,
            textInputAction: TextInputAction.next,
          ),
        if (_tokenRequested)
          TextField(
            decoration: InputDecoration(
              label: Text('New Password'),
              suffixIcon: passwordVisible
                  ? IconButton(
                      icon: Icon(Icons.visibility_off_outlined),
                      onPressed: () => setState(() => passwordVisible = false),
                    )
                  : IconButton(
                      icon: Icon(Icons.visibility_outlined),
                      onPressed: () => setState(() => passwordVisible = true),
                    ),
            ),
            controller: _passwordController,
            obscureText: !passwordVisible,
            enableSuggestions: false,
            autocorrect: false,
            autofocus: true,
            autofillHints: const [AutofillHints.newPassword],
            keyboardType: TextInputType.visiblePassword,
            onSubmitted: _requestInFlight
                ? null
                : (value) => _changePassword(context),
          ),
        if (_tokenRequested)
          ValueListenableBuilder(
            valueListenable: _emailController,
            builder: (_, email, __) => ValueListenableBuilder(
              valueListenable: _tokenController,
              builder: (_, token, __) {
                return ValueListenableBuilder(
                  valueListenable: _passwordController,
                  builder: (_, password, __) => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    label: Text(
                      _requestInFlight
                          ? 'Logging In'
                          : 'Change Password and Log In',
                    ),
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
                            password.text.isEmpty ||
                            token.text.isEmpty
                        ? null
                        : () => _changePassword(context),
                  ),
                );
              },
            ),
          )
        else
          ValueListenableBuilder(
            valueListenable: _emailController,
            builder: (_, email, __) => ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(
                _requestInFlight
                    ? 'Requesting Reset Token'
                    : 'Request Reset Token',
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
                  : () => _requestReset(context),
            ),
          ),
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
    );
  }

  Future<void> _requestReset(BuildContext context) async {
    if (_requestInFlight) return;
    final instanceUrl = context.read<LoginState>().instanceInfo!.url;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/request-reset';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;

    setState(() => _requestInFlight = true);
    final result = await sendRequest(request);
    final success = result is SuccessResponse;
    setState(() {
      _requestInFlight = false;
      _tokenRequested = success;
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Reset Token sent via Email' : result.toString(),
        ),
      ),
    );
  }

  void _changePassword(BuildContext context) async {
    if (_requestInFlight) return;
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/reset';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;
    request.fields['token'] = _tokenController.text;
    request.fields['password'] = _passwordController.text;

    setState(() => _requestInFlight = true);
    await login(context, request);
    setState(() => _requestInFlight = false);
  }
}
