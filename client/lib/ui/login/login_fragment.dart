import 'package:flutter/material.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/magic_link_login.dart';
import 'package:phylum/ui/login/password_login.dart';
import 'package:uri/uri.dart';

import 'oauth_stub.dart'
    if (dart.library.js_interop) 'oauth_web.dart'
    if (dart.library.ffi) 'oauth_vm.dart';

class LoginFragment extends StatelessWidget {
  final InstanceInfo instanceInfo;
  final Function()? onBackPressed;

  const LoginFragment({
    super.key,
    required this.instanceInfo,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButtonTheme(
        data: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            TextFormField(
              decoration: InputDecoration(
                label: const Text('Instance URL'),
                prefixIcon: Icon(Icons.storage),
                suffixIcon: IconButton(
                  onPressed: onBackPressed,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.edit),
                  iconSize: 18,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
              initialValue: instanceInfo.url.toString(),
              keyboardType: TextInputType.url,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 48, right: 48),
              child: Divider(),
            ),
            buildPage(context),
          ],
        ));
  }

  Widget buildPage(BuildContext context) {
    final authConfig = instanceInfo.authConfig!;
    if (authConfig.password &&
        !authConfig.magicLinks &&
        authConfig.openIDProviders.isEmpty) {
      return PasswordLogin(instanceUrl: instanceInfo.url);
    } else if (authConfig.magicLinks &&
        !authConfig.password &&
        authConfig.openIDProviders.isEmpty) {
      return MagicLinkLogin(instanceUrl: instanceInfo.url);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (authConfig.password)
          ElevatedButton.icon(
            onPressed: () async {},
            icon: Icon(Icons.password),
            label: Text('Password'),
          ),
        if (authConfig.magicLinks)
          ElevatedButton.icon(
            onPressed: () async {},
            icon: Icon(Icons.email),
            label: Text('Email'),
          ),
        ...authConfig.openIDProviders.map((p) => ElevatedButton(
            onPressed: () async {
              final builder = UriBuilder.fromUri(instanceInfo.url);
              builder.path += '/api/v1/auth/oauth/start';
              builder.queryParameters['provider'] = p.id;
              startOAuthFlow(context, builder, p.name);
            },
            child: Text(p.name))),
      ],
    );
  }
}
