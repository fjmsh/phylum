import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/config/remote_config.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';

class SetupConfig {
  final RemoteConfig<MailConfigFields> mailConfig;
  final RemoteConfig<AuthConfigFields> authConfig;

  SetupConfig._({required this.mailConfig, required this.authConfig});

  factory SetupConfig.fromMap(Map<String, dynamic> data) {
    final config = (data['config'] as Map).cast<String, dynamic>();
    return SetupConfig._(
      mailConfig: RemoteConfig.fromMap(
        const MailConfigFields(),
        (config['mail'] as Map).cast(),
      ),
      authConfig: RemoteConfig.fromMap(
        const AuthConfigFields(),
        (config['auth'] as Map).cast(),
      ),
    );
  }
}
