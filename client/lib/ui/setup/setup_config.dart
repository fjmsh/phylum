import 'package:phylum/ui/settings/config/remote_config.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';

class SetupConfig {
  final RemoteConfig mailConfig;

  SetupConfig._({required this.mailConfig});

  factory SetupConfig.fromMap(Map<String, dynamic> data) {
    final config = (data['config'] as Map).cast<String, dynamic>();
    final mailConfig = (config['mail'] as Map).cast<String, dynamic>();
    final remoteMailConfig = RemoteConfig.fromMap(
      (mailConfig['config'] as Map).cast(),
      Set.of(mailConfig['overrides'] as List).cast(),
      MailConfigFields.fields,
    );
    return SetupConfig._(mailConfig: remoteMailConfig);
  }
}
