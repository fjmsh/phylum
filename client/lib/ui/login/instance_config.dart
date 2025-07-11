import 'dart:convert';

class InstanceConfig {
  final Uri url;
  final bool password;
  final bool passwordReset;
  final bool magicLink;
  final List<OpenIDProvider> openIDProviders;

  bool get hasEmailLogin => password || magicLink;

  InstanceConfig(
      {required this.url,
      required this.password,
      required this.passwordReset,
      required this.magicLink,
      required this.openIDProviders});

  factory InstanceConfig.fromResponse(Uri url, String responseString) {
    final config = (jsonDecode(responseString) as Map).cast<String, dynamic>();
    final providers = (config['openid_providers'] as List).cast<Map>();
    return InstanceConfig(
      url: url,
      password: config['password'],
      passwordReset: config['password_reset'],
      magicLink: false,
      openIDProviders:
          providers.map((e) => OpenIDProvider.fromResponse(url, e.cast<String, dynamic>())).toList(growable: false),
    );
  }

  @override
  String toString() {
    return 'Instance at $url: $password';
  }
}

class OpenIDProvider {
  final String id;
  final String name;

  OpenIDProvider({required this.id, required this.name});

  factory OpenIDProvider.fromResponse(Uri url, Map<String, dynamic> response) {
    return OpenIDProvider(
      id: response['id'],
      name: response['name'],
    );
  }
}
