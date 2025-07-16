import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/request.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';

class TokenLoginPage extends StatefulWidget {
  final String? instanceUrl;
  final String? loginToken;

  const TokenLoginPage({
    super.key,
    required this.instanceUrl,
    required this.loginToken,
  });

  @override
  State<TokenLoginPage> createState() => _TokenLoginPageState();
}

class _TokenLoginPageState extends State<TokenLoginPage> {
  late final instanceUrlController = TextEditingController(text: widget.instanceUrl);
  late final loginTokenController = TextEditingController(text: widget.loginToken);

  @override
  void initState() {
    super.initState();
    if (widget.instanceUrl != null && widget.loginToken != null) {
      final instanceUrl = Uri.tryParse(widget.instanceUrl!);
      if (instanceUrl != null) {
        WidgetsBinding.instance.addPostFrameCallback((d) {
          _performLogin(context, instanceUrl, widget.loginToken!);
        });
      }
    }
  }

  @override
  void dispose() {
    instanceUrlController.dispose();
    loginTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhylumDialogScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6.0,
        children: [
          TextField(
            decoration: InputDecoration(
              label: Text('Instance URL'),
              hintText: 'https://phylum.example.com',
            ),
            controller: instanceUrlController,
            enabled: widget.instanceUrl == null,
            keyboardType: TextInputType.url,
          ),
          TextField(
            decoration: InputDecoration(
              label: Text('Login Token'),
              hintText: 'AG...',
            ),
            controller: loginTokenController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (value) {
              final instanceUrl = Uri.tryParse(instanceUrlController.value.text);
              if (instanceUrl != null) {
                _performLogin(context, instanceUrl, value);
              }
            },
          ),
          ElevatedButton(
            onPressed: () {
              final instanceUrl = Uri.tryParse(instanceUrlController.value.text);
              if (instanceUrl != null) {
                _performLogin(context, instanceUrl, loginTokenController.value.text);
              }
            },
            child: Text('Log In'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogin(BuildContext context, Uri instanceUrl, String token) async {
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/login';
    final request = MultipartRequest('post', builder.build());
    request.fields['token'] = token;

    final responseString = await sendRequest(context, 'Logging In', request);
    if (responseString == null) return;
    if (context.mounted) {
      final routerDelegate = context.read<PhylumRouterDelegate>();
      final accountManager = context.read<AccountManager<PhylumAccount>>();
      final navigator = Navigator.of(context);
      showProgressDialog(context, barrierDismissible: false, message: 'Logging In');
      try {
        final response =
            BootstrapLoginResponse.fromResponse((jsonDecode(responseString) as Map).cast<String, dynamic>());
        final account = await PhylumAccount.create(
          serverUrl: instanceUrl,
          apiToken: response.apiToken!,
          user: response.user,
        );
        await response.process(account);
        await accountManager.addAccount(account);
        navigator.pop();
        routerDelegate.go(const ExplorerRouteHome());
      } catch (e, stack) {
        navigator.pop();
        if (context.mounted) {
          showAlertDialog(
            context,
            barrierDismissible: false,
            title: 'Error',
            message: e.toString(),
          );
        }
        logger.w('Login Error', error: e, stackTrace: stack);
      }
    }
  }
}
