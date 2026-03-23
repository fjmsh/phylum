import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? instanceUrl;
  final String? email;
  final String? token;

  const ResetPasswordPage({
    super.key,
    required this.instanceUrl,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  String _password = '';
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    if (widget.instanceUrl == null || widget.email == null || widget.token == null) {
      return PhylumDialogScaffold(
          child: Column(
        children: [
          const Text('Mising parameters'),
          ElevatedButton(
            child: Text('OK'),
            onPressed: () => context.read<PhylumRouterDelegate>().go(ExplorerRouteHome()),
          ),
        ],
      ));
    }
    return PhylumDialogScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6.0,
        children: [
          const Text('Reset Password', style: TextStyle(fontSize: 18)),
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
            obscureText: !passwordVisible,
            enableSuggestions: false,
            autocorrect: false,
            autofocus: true,
            autofillHints: const [AutofillHints.newPassword],
            keyboardType: TextInputType.visiblePassword,
            onChanged: (value) => _password = value,
            onSubmitted: (value) => changePassword(context),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onPressed: () => context.read<PhylumRouterDelegate>().go(ExplorerRouteHome()),
              ),
              ElevatedButton(
                onPressed: () => changePassword(context),
                child: Text('Change Password'),
              )
            ],
          ),
        ],
      ),
    );
  }

  void changePassword(
    BuildContext context,
  ) async {
    final instanceUrl = Uri.parse(widget.instanceUrl!);
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/password/reset';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = widget.email!;
    request.fields['token'] = widget.token!;
    request.fields['password'] = _password;

    final responseString = await sendRequest(context, 'Changing Password', request);
    if (responseString == null) return;
    if (context.mounted) {
      final navigator = Navigator.of(context);
      final routerDelegate = context.read<PhylumRouterDelegate>();
      final accountManager = context.read<AccountManager<PhylumAccount>>();
      showProgressDialog(context, message: 'Password Changed. Logging In');

      final response = BootstrapLoginResponse.fromResponse((jsonDecode(responseString) as Map).cast<String, dynamic>());
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
