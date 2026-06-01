import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

class MagicLinkLogin extends StatelessWidget {
  final Uri instanceUrl;
  final _emailController = TextEditingController();

  MagicLinkLogin({super.key, required this.instanceUrl});

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          TextField(
            decoration: const InputDecoration(
              label: Text('Email'),
              prefixIcon: Icon(Icons.email),
            ),
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text('Request Email Login Link'),
            icon: Icon(Icons.email),
            onPressed: _emailController.text.isEmpty
                ? null
                : () => _requestMagicLink(context),
          ),
        ],
      ),
    );
  }

  Future<void> _requestMagicLink(BuildContext context) async {
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

      context.read<PhylumRouterDelegate>().go(TokenLoginRoute(
            instanceUrl: instanceUrl.toString(),
          ));
    }
  }
}
