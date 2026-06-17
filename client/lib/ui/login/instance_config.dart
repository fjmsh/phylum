import 'dart:convert';

class InstanceInfo {
  final Uri url;
  final bool needsSetup;
  final AuthConfig? authConfig;

  InstanceInfo({
    required this.url,
    required this.needsSetup,
    required this.authConfig,
  });

  factory InstanceInfo.fromResponse(Uri url, String responseString) {
    final config = (jsonDecode(responseString) as Map).cast<String, dynamic>();
    return InstanceInfo(
      url: url,
      needsSetup: config['needs_config'],
      authConfig: config.containsKey('auth')
          ? AuthConfig.fromResponse(config['auth'].cast<String, dynamic>())
          : null,
    );
  }

  @override
  String toString() {
    return 'Instance at $url${needsSetup ? '(needs config)' : ''}${authConfig ?? ''}';
  }
}

class AuthConfig {
  final bool password;
  final bool passwordReset;
  final bool magicLinks;
  final List<OpenIDProvider> openIDProviders;

  bool get email => password || magicLinks;

  AuthConfig({
    required this.password,
    required this.passwordReset,
    required this.magicLinks,
    required this.openIDProviders,
  });

  factory AuthConfig.fromResponse(Map<String, dynamic> configMap) {
    final providers = (configMap['openid_providers'] as List).cast<Map>();
    return AuthConfig(
      password: configMap['password'],
      passwordReset: configMap['password_reset'],
      magicLinks: configMap['magic_links'],
      openIDProviders: providers
          .map((e) => OpenIDProvider.fromResponse(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  @override
  String toString() {
    final methods = [
      if (password) 'Password',
      if (passwordReset) 'Password Reset',
      if (magicLinks) 'Passwordless',
      ...openIDProviders.map((p) => 'OIDC: ${p.name}'),
    ];
    return 'Auth Config (${methods.join(',')})';
  }
}

class OpenIDProvider {
  final String id;
  final String name;

  OpenIDProvider({required this.id, required this.name});

  factory OpenIDProvider.fromResponse(Map<String, dynamic> providerMap) {
    return OpenIDProvider(id: providerMap['id'], name: providerMap['name']);
  }
}
