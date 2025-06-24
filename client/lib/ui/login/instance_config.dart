import 'dart:convert';

class InstanceConfig {
  final Uri url;
  final bool password;
  final bool passwordReset;
  final bool magicLink;

  InstanceConfig({
    required this.url,
    required this.password,
    required this.passwordReset,
    required this.magicLink,
  });

  factory InstanceConfig.fromResponse(Uri url, String responseString) {
    final config = (jsonDecode(responseString) as Map).cast<String, dynamic>();
    return InstanceConfig(
      url: url,
      password: config['password'],
      passwordReset: config['password_reset'],
      magicLink: false,
    );
  }
  @override
  String toString() {
    return 'Instance at $url: $password';
  }
}
