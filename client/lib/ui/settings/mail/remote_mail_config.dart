import 'package:phylum/ui/settings/mail/mail_config.dart';

class RemoteConfig {
  final Map<ConfigFieldDef, RemoteConfigField?> values;

  RemoteConfig({required this.values});

  factory RemoteConfig.fromMap(
    Map<String, dynamic> map,
    Set<String> fixed,
    List<ConfigFieldDef> fields,
  ) {
    final values = <ConfigFieldDef, RemoteConfigField?>{};
    for (final field in fields) {
      values[field] = RemoteConfigField.create(map, fixed, field);
    }
    return RemoteConfig(values: values);
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    for (final entry in values.entries) {
      String path = entry.key.path;
      Map<String, dynamic> map = result;
      while (path.contains(".")) {
        final i = path.indexOf(".");
        final key = path.substring(0, i);
        if (map[key] == null) {
          final m = <String, dynamic>{};
          map[key] = m;
          map = m;
        } else if (map[key] is Map<String, dynamic>) {
          map = map[key];
        } else {}
        path = path.substring(i + 1);
      }
      map[path] = entry.value?.value;
    }
    return result;
  }
}

class ConfigFieldDef<T> {
  final String path;
  final T defaultValue;

  const ConfigFieldDef({required this.path, required this.defaultValue});
}

class RemoteConfigField<T> {
  final ConfigFieldDef<T> field;
  final T value;
  final bool fixed;

  RemoteConfigField._({
    required this.field,
    required this.value,
    required this.fixed,
  });

  factory RemoteConfigField.create(
    Map<String, dynamic>? map,
    Set<String> fixed,
    ConfigFieldDef<T> field,
  ) {
    String path = field.path;
    while (path.contains(".")) {
      final i = path.indexOf(".");
      map = map?[path.substring(0, i)];
      path = path.substring(i + 1);
    }
    return RemoteConfigField._(
      field: field,
      value: map?[path] ?? field.defaultValue,
      fixed: fixed.contains(field.path),
    );
  }

  @override
  bool operator ==(covariant RemoteConfigField<T> other) {
    if (identical(this, other)) return true;
    return field == other.field && value == other.value && fixed == other.fixed;
  }

  @override
  int get hashCode => value.hashCode ^ fixed.hashCode;
}

class MailConfigFields {
  static const fieldEnabled = ConfigFieldDef(
    path: "enabled",
    defaultValue: true,
  );
  static const fieldSmtpHost = ConfigFieldDef(
    path: "smtp.host",
    defaultValue: "",
  );
  static const fieldSmtpPort = ConfigFieldDef(
    path: "smtp.port",
    defaultValue: 587,
  );
  static const fieldSmtpUsername = ConfigFieldDef(
    path: "smtp.username",
    defaultValue: "",
  );
  static const fieldSmtpPassword = ConfigFieldDef(
    path: "smtp.password",
    defaultValue: "",
  );
  static const fieldFromName = ConfigFieldDef(
    path: "from.name",
    defaultValue: "Phylum Drive",
  );
  static const fieldFromEmail = ConfigFieldDef(
    path: "from.email",
    defaultValue: "",
  );
  static const fieldInstance = ConfigFieldDef(
    path: "instance",
    defaultValue: "",
  );

  static const fields = [
    fieldEnabled,
    fieldSmtpHost,
    fieldSmtpPort,
    fieldSmtpUsername,
    fieldSmtpPassword,
    fieldFromName,
    fieldFromEmail,
    fieldInstance,
  ];
}

class RemoteMailConfig {
  final RemoteConfigField<bool> enabled;
  final RemoteConfigField<String> smtpHost;
  final RemoteConfigField<int> smtpPort;
  final RemoteConfigField<String> smtpUsername;
  final RemoteConfigField<String> smtpPassword;
  final RemoteConfigField<String> fromName;
  final RemoteConfigField<String> fromEmail;
  final RemoteConfigField<String> instanceUrl;

  const RemoteMailConfig._({
    required this.enabled,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.fromName,
    required this.fromEmail,
    required this.instanceUrl,
  });

  factory RemoteMailConfig.fromMap(
    Map<String, dynamic> map,
    Set<String> fixedPaths,
  ) {
    return RemoteMailConfig._(
      enabled: RemoteConfigField.create(map, fixedPaths, "enabled", false),
      smtpHost: RemoteConfigField.create(map, fixedPaths, "smtp.host", ""),
      smtpPort: RemoteConfigField.create(map, fixedPaths, "smtp.port", 587),
      smtpUsername: RemoteConfigField.create(
        map,
        fixedPaths,
        "smtp.username",
        "",
      ),
      smtpPassword: RemoteConfigField.create(
        map,
        fixedPaths,
        "smtp.password",
        "",
      ),
      fromName: RemoteConfigField.create(
        map,
        fixedPaths,
        "from.name",
        "Phylum Drive",
      ),
      fromEmail: RemoteConfigField.create(map, fixedPaths, "from.email", ""),
      instanceUrl: RemoteConfigField.create(map, fixedPaths, "instance", ""),
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled.value,
    'smtp': {
      'host': smtpHost.value,
      'port': smtpPort.value,
      'username': smtpUsername.value,
      'password': smtpPassword.value,
    },
    'from': {'name': fromName.value, 'email': fromEmail.value},
    'instance': instanceUrl.value,
  };

  Map<String, dynamic> toMapDiff(MailConfig config) => {
    if (enabled.value != config.enabled) 'enabled': enabled,
    'smtp': {
      if (smtpHost.value != config.smtpHost) 'host': smtpHost,
      if (smtpPort.value != config.smtpPort) 'port': smtpPort,
      if (smtpUsername.value != config.smtpUsername) 'username': smtpUsername,
      if (smtpPassword.value != config.smtpPassword) 'password': smtpPassword,
    },
    'from': {
      if (fromName.value != config.fromName) 'name': fromName,
      if (fromEmail.value != config.fromEmail) 'email': fromEmail,
    },
    if (instanceUrl.value != config.instanceUrl) 'instance': instanceUrl,
  };

  @override
  bool operator ==(covariant RemoteMailConfig other) {
    if (identical(this, other)) return true;

    return other.enabled == enabled &&
        other.smtpHost == smtpHost &&
        other.smtpPort == smtpPort &&
        other.smtpUsername == smtpUsername &&
        other.smtpPassword == smtpPassword &&
        other.fromEmail == fromEmail &&
        other.fromName == fromName &&
        other.instanceUrl == instanceUrl;
  }

  @override
  int get hashCode =>
      enabled.hashCode ^
      smtpHost.hashCode ^
      smtpPort.hashCode ^
      smtpUsername.hashCode ^
      smtpPassword.hashCode ^
      fromEmail.hashCode ^
      fromName.hashCode ^
      instanceUrl.hashCode;
}
