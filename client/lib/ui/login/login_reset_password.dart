import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'login_controller.dart';

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
  bool passwordVisible = false;

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
        InstanceUrlFragment(readonly: true),
        TextField(
          decoration: InputDecoration(label: Text('Email')),
          controller: _emailController,
          readOnly: widget.email != null,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofocus: widget.email == null,
          textInputAction: TextInputAction.next,
        ),
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
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
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
          autofocus: widget.token == null,
          textInputAction: TextInputAction.next,
        ),
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
          onSubmitted: (value) => changePassword(context),
        ),
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
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      label: Text('Reset Password and Login'),
                      icon: Icon(Icons.login),
                      onPressed: email.text.isEmpty ||
                              password.text.isEmpty ||
                              token.text.isEmpty
                          ? null
                          : () => changePassword(context),
                    ),
                  );
                })),
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

  void changePassword(BuildContext context) async {
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/reset';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;
    request.fields['token'] = _tokenController.text;
    request.fields['password'] = _passwordController.text;

    final responseString =
        await sendRequest(context, 'Changing Password', request);
    if (responseString == null) return;
    if (context.mounted) {
      final navigator = Navigator.of(context);
      final routerDelegate = context.read<PhylumRouterDelegate>();
      final accountManager = context.read<AccountManager<PhylumAccount>>();
      showProgressDialog(context, message: 'Password Changed. Logging In');

      final response = BootstrapLoginResponse.fromResponse(
          (jsonDecode(responseString) as Map).cast<String, dynamic>());
      final account = await PhylumAccount.create(
        serverUrl: instanceUrl,
        apiToken: response.apiToken!,
        user: response.user,
      );
      await response.process(account);
      await accountManager.addAccount(account);
      navigator.pop();
      routerDelegate.go(ExplorerRouteHome());
    }
  }
}
