import 'package:flutter/material.dart';
import 'package:phylum/ui/login/instance_url_field.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'oauth_stub.dart'
    if (dart.library.js_interop) 'oauth_web.dart'
    if (dart.library.ffi) 'oauth_vm.dart';

class LoginSelector extends StatelessWidget {
  const LoginSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final instanceInfo = context.read<LoginState>().instanceInfo;
    final authConfig = instanceInfo!.authConfig!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        const InstanceUrlField(),
        if (authConfig.email)
          ElevatedButton.icon(
            onPressed: () => context.read<LoginController>().selectedMethod =
                EmailLoginMethod(),
            icon: Icon(Icons.email),
            label: Text('Email'),
          ),
        ...authConfig.openIDProviders.map(
          (p) => ElevatedButton(
            onPressed: () async {
              final builder = UriBuilder.fromUri(instanceInfo.url);
              builder.path += '/api/v1/auth/oauth/start';
              builder.queryParameters['provider'] = p.id;
              startOAuthFlow(context, builder, p.name);
            },
            child: Text(p.name),
          ),
        ),
      ],
    );
  }
}
