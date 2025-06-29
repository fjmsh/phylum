import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';

class TokenLoginPage extends StatefulWidget {
  final String instanceUrl;
  final String loginToken;

  const TokenLoginPage({
    super.key,
    required this.instanceUrl,
    required this.loginToken,
  });

  @override
  State<TokenLoginPage> createState() => _TokenLoginPageState();
}

class _TokenLoginPageState extends State<TokenLoginPage> {
  String? error;

  @override
  void initState() {
    super.initState();
    performLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return PhylumDialogScaffold(
      child: error == null
          ? const Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12.0,
              children: [
                CircularProgressIndicator(),
                Text('Logging In'),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 6.0,
              children: [
                Text('Error: $error'),
                ElevatedButton(
                    onPressed: () {
                      context.read<PhylumRouterDelegate>().go(ExplorerRouteHome());
                    },
                    child: Text('OK'))
              ],
            ),
    );
  }

  void performLogin(BuildContext context) async {
    final instanceUrl = Uri.parse(widget.instanceUrl);
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/login';
    final request = MultipartRequest('post', builder.build());
    request.fields['login_token'] = widget.loginToken;

    try {
      final response = await Client().send(request);
      final responseString = await response.stream.bytesToString();
      final responseMap = (jsonDecode(responseString) as Map).cast<String, dynamic>();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (context.mounted) {
          final navigator = Navigator.of(context);
          final routerDelegate = context.read<PhylumRouterDelegate>();
          final accountManager = context.read<AccountManager<PhylumAccount>>();

          final response = BootstrapLoginResponse.fromResponse(responseMap);
          final account = await PhylumAccount.create(
            serverUrl: instanceUrl,
            apiKey: response.apiKey!,
            user: response.user,
          );
          await response.process(account);
          await accountManager.addAccount(account);
          navigator.pop();
          routerDelegate.go(ExplorerRouteHome());
        }
      } else {
        if (context.mounted) {
          setState(() => error = responseMap['msg']);
        }
        return null;
      }
    } on SocketException {
      if (context.mounted) {
        setState(() => error = 'unable to reach server');
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        setState(() => error = e.toString());
      }
      return null;
    }
  }
}
