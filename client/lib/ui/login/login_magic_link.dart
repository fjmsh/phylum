import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/instance_url_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'login_controller.dart';

class MagicLinkLogin extends StatefulWidget {
  const MagicLinkLogin({super.key});

  @override
  State<MagicLinkLogin> createState() => _MagicLinkLoginState();
}

class _MagicLinkLoginState extends State<MagicLinkLogin> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          const InstanceUrlFragment(readonly: true),
          TextField(
            key: ValueKey('email'),
            decoration: const InputDecoration(
              label: Text('Email'),
              prefixIcon: Icon(Icons.email),
            ),
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          ValueListenableBuilder(
              valueListenable: _emailController,
              builder: (_, email, __) {
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text('Request Email Login Link'),
                  icon: Icon(Icons.email),
                  onPressed: email.text.isEmpty
                      ? null
                      : () => _requestMagicLink(context),
                );
              }),
          if (context.read<LoginState>().selectedMethod != null)
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
      ),
    );
  }

  Future<void> _requestMagicLink(BuildContext context) async {
    final instanceUrl = context.read<LoginState>().instanceInfo!.url;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/request';
    final request = MultipartRequest('post', builder.build());
    request.fields['email'] = _emailController.text;

    final responseString =
        await sendRequest(context, 'Requesting Login Link', request);
    if (responseString == null) return;
    if (context.mounted) {
      final response = await showAlertDialog(
        context,
        title: 'Login Link Sent',
        message: 'Please check your email for a login link',
        negativeText: 'Enter Manually',
        colorNegative: false,
      );

      if ((response ?? true) || !context.mounted) return;

      context
          .read<PhylumRouterDelegate>()
          .go(TokenLoginRoute(instanceUrl: instanceUrl.toString()));
    }
  }
}
