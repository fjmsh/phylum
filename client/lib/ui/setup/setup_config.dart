import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/ui/setup/db/db_config.dart';

class SetupConfig {
  final RemoteConfig<DbConfigFields> dbConfig;
  final RemoteConfig<MailConfigFields> mailConfig;
  final RemoteConfig<AuthConfigFields> authConfig;

  SetupConfig._({
    required this.dbConfig,
    required this.mailConfig,
    required this.authConfig,
  });

  factory SetupConfig.fromMap(Map<String, dynamic> data) {
    final config = (data['config'] as Map).cast<String, dynamic>();
    return SetupConfig._(
      dbConfig: RemoteConfig.fromMap(
        DbConfigFields.instance,
        (config['db'] as Map).cast(),
      ),
      mailConfig: RemoteConfig.fromMap(
        MailConfigFields.instance,
        (config['mail'] as Map).cast(),
      ),
      authConfig: RemoteConfig.fromMap(
        const AuthConfigFields(),
        (config['auth'] as Map).cast(),
      ),
    );
  }
}
