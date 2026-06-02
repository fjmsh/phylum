import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'instance_url.dart';
import 'login_controller.dart';

class TokenLogin extends StatefulWidget {
  final String? token;

  const TokenLogin({
    super.key,
    required this.token,
  });

  @override
  State<TokenLogin> createState() => _TokenLoginState();
}

class _TokenLoginState extends State<TokenLogin> {
  late final tokenController = TextEditingController(text: widget.token);

  @override
  void initState() {
    super.initState();
    if (widget.token?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((d) {
        _performLogin(context);
      });
    }
  }

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        LoginInstanceUrl(display: true),
        TextField(
          decoration: InputDecoration(
            label: Text('Login Token'),
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
                          tokenController.text = text;
                        }
                      }
                    },
                  ),
          ),
          controller: tokenController,
          readOnly: widget.token != null,
          keyboardType: TextInputType.text,
          autocorrect: false,
          autofocus: true,
          textInputAction: TextInputAction.go,
          onSubmitted: (value) => _performLogin(context),
        ),
        ValueListenableBuilder(
            valueListenable: tokenController,
            builder: (_, token, __) => ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text('Login'),
                  icon: Icon(Icons.login),
                  onPressed:
                      token.text.isEmpty ? null : () => _performLogin(context),
                )),
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

  Future<void> _performLogin(BuildContext context) async {
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/login';
    final request = MultipartRequest('post', builder.build());
    request.fields['token'] = tokenController.text;

    final responseString = await sendRequest(context, 'Logging In', request);
    if (responseString == null) return;
    if (context.mounted) {
      final routerDelegate = context.read<PhylumRouterDelegate>();
      final accountManager = context.read<AccountManager<PhylumAccount>>();
      final navigator = Navigator.of(context);
      showProgressDialog(context,
          barrierDismissible: false, message: 'Logging In');
      try {
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
