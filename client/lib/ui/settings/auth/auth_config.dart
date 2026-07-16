import 'package:collection/collection.dart';

class AuthConfig {
  final bool passwordlessLoginEnabled;
  final PasswordConfig passwordConfig;
  final Map<String, OpenIDConfig> openIdConfigs;

  bool get passwordLoginEnabled =>
      passwordConfig.backend != PasswordBackend.none;

  const AuthConfig({
    required this.passwordlessLoginEnabled,
    required this.passwordConfig,
    required this.openIdConfigs,
  });

  AuthConfig.defaults()
    : this(
        passwordlessLoginEnabled: false,
        passwordConfig: PasswordConfig.defaults(),
        openIdConfigs: const {},
      );

  bool get valid =>
      passwordConfig.backend != PasswordBackend.none ||
      passwordlessLoginEnabled ||
      openIdConfigs.isNotEmpty;

  AuthConfig copyWith({
    PasswordConfig? passwordConfig,
    bool? passwordlessLoginEnabled,
    Map<String, OpenIDConfig>? openIdConfigs,
  }) {
    return AuthConfig(
      passwordlessLoginEnabled:
          passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
      passwordConfig: passwordConfig ?? this.passwordConfig,
      openIdConfigs: openIdConfigs ?? this.openIdConfigs,
    );
  }

  factory AuthConfig.fromMap(Map<String, dynamic> data) {
    final clients = data['openid']?['clients'];
    final config = AuthConfig(
      passwordlessLoginEnabled: data['magic_links'],
      passwordConfig: data.containsKey('password')
          ? PasswordConfig.fromMap((data['password'] as Map).cast())
          : PasswordConfig.defaults(),
      openIdConfigs: clients == null
          ? const {}
          : Map.fromEntries(
              (clients as Map)
                  .cast<String, dynamic>()
                  .entries
                  .map<MapEntry<String, OpenIDConfig>>(
                    (e) => MapEntry(
                      e.key,
                      OpenIDConfig.fromMap(e.key, (e.value as Map).cast()),
                    ),
                  ),
            ),
    );
    return config;
  }

  Map<String, dynamic> toMapDiff(AuthConfig old) {
    final clients = openIdConfigs.map((key, value) {
      return MapEntry(
        key,
        value.toMapDiff(old.openIdConfigs[key] ?? OpenIDConfig.empty()),
      );
    });
    return {
      'password': passwordConfig.toMap(),
      'magic_links': passwordlessLoginEnabled,
      'openid': {'clients': clients},
    };
  }

  @override
  String toString() {
    return 'AuthConfig(passwordlessLoginEnabled: $passwordlessLoginEnabled, passwordConfig: $passwordConfig, openIdConfigs: $openIdConfigs)';
  }

  @override
  bool operator ==(covariant AuthConfig other) {
    if (identical(this, other)) return true;

    return other.passwordlessLoginEnabled == passwordlessLoginEnabled &&
        other.passwordConfig == passwordConfig &&
        (const DeepCollectionEquality()).equals(
          other.openIdConfigs,
          openIdConfigs,
        );
  }

  @override
  int get hashCode =>
      passwordlessLoginEnabled.hashCode ^
      passwordConfig.hashCode ^
      openIdConfigs.hashCode;
}

class PasswordConfig {
  final PasswordBackend backend;
  final CryptConfig cryptConfig;
  final LdapConfig ldapConfig;
  final bool resetEnabled;

  const PasswordConfig({
    required this.backend,
    required this.cryptConfig,
    required this.ldapConfig,
    required this.resetEnabled,
  });

  PasswordConfig.defaults()
    : this(
        backend: PasswordBackend.none,
        cryptConfig: CryptConfig.defaults(),
        ldapConfig: LdapConfig.defaults(),
        resetEnabled: false,
      );

  factory PasswordConfig.fromMap(Map<String, dynamic> data) {
    return PasswordConfig(
      backend: PasswordBackend.fromString(data['backend']),
      cryptConfig: data.containsKey('crypt')
          ? CryptConfig.fromMap((data['crypt'] as Map).cast())
          : CryptConfig.defaults(),
      ldapConfig: data.containsKey('ldap')
          ? LdapConfig.fromMap((data['ldap'] as Map).cast())
          : LdapConfig.defaults(),
      resetEnabled: data['reset_enabled'] ?? false,
    );
  }

  PasswordConfig copyWith({
    PasswordBackend? backend,
    CryptConfig? cryptConfig,
    LdapConfig? ldapConfig,
    bool? resetEnabled,
  }) {
    return PasswordConfig(
      backend: backend ?? this.backend,
      cryptConfig: cryptConfig ?? this.cryptConfig,
      ldapConfig: ldapConfig ?? this.ldapConfig,
      resetEnabled: resetEnabled ?? this.resetEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return switch (backend) {
      .none => {'backend': 'none'},
      .crypt => {
        'backend': 'crypt',
        'crypt': cryptConfig.toMap(),
        'reset_enabled': resetEnabled,
      },
      .ldap => {
        'backend': 'ldap',
        'ldap': ldapConfig.toMap(),
        'reset_enabled': false,
      },
    };
  }

  @override
  String toString() {
    return 'PasswordConfig(backend: $backend, cryptConfig: $cryptConfig, ldapConfig: $ldapConfig, resetEnabled: $resetEnabled)';
  }

  @override
  bool operator ==(covariant PasswordConfig other) {
    if (identical(this, other)) return true;

    return other.backend == backend &&
        other.cryptConfig == cryptConfig &&
        other.ldapConfig == ldapConfig &&
        other.resetEnabled == resetEnabled;
  }

  @override
  int get hashCode {
    return backend.hashCode ^
        cryptConfig.hashCode ^
        ldapConfig.hashCode ^
        resetEnabled.hashCode;
  }
}

enum PasswordBackend {
  none('none', 'Disabled'),
  crypt('crypt', 'Crypt (Local DB)'),
  ldap('ldap', 'LDAP');

  final String name;
  final String descriptor;

  const PasswordBackend(this.name, this.descriptor);

  static PasswordBackend fromString(String s) {
    return switch (s) {
      'crypt' => .crypt,
      'ldap' => .ldap,
      _ => .none,
    };
  }
}

class CryptConfig {
  final CryptKDF kdf;
  final Argon2Config argon2Config;
  final Pbkdf2Config pbkdf2Config;

  const CryptConfig({
    required this.kdf,
    required this.argon2Config,
    required this.pbkdf2Config,
  });

  CryptConfig.defaults()
    : this(
        kdf: CryptKDF.argon2,
        argon2Config: Argon2Config.defaults(),
        pbkdf2Config: Pbkdf2Config.defaults(),
      );

  factory CryptConfig.fromMap(Map<String, dynamic> data) {
    return CryptConfig(
      kdf: CryptKDF.fromString(data['kdf']),
      argon2Config: Argon2Config.fromMap((data['argon2'] as Map).cast()),
      pbkdf2Config: Pbkdf2Config.fromMap((data['pbkdf2'] as Map).cast()),
    );
  }

  CryptConfig copyWith({
    CryptKDF? kdf,
    Argon2Config? argon2Config,
    Pbkdf2Config? pbkdf2Config,
  }) => CryptConfig(
    kdf: kdf ?? this.kdf,
    argon2Config: argon2Config ?? this.argon2Config,
    pbkdf2Config: pbkdf2Config ?? this.pbkdf2Config,
  );

  Map<String, dynamic> toMap() => switch (kdf) {
    CryptKDF.argon2 => {'kdf': 'argon2', 'argon2': argon2Config.toMap()},
    CryptKDF.pbkdf2 => {'kdf': 'pbkdf2', 'pbkdf2': pbkdf2Config.toMap()},
  };

  @override
  String toString() =>
      'CryptConfig(kdf: $kdf, argon2Config: $argon2Config, pbkdf2Config: $pbkdf2Config)';

  String get description => switch (kdf) {
    CryptKDF.argon2 => 'Argon2 (${argon2Config.description})',
    CryptKDF.pbkdf2 => 'PBKDF2 (${pbkdf2Config.description})',
  };

  @override
  bool operator ==(covariant CryptConfig other) {
    if (identical(this, other)) return true;

    return other.kdf == kdf &&
        other.argon2Config == argon2Config &&
        other.pbkdf2Config == pbkdf2Config;
  }

  @override
  int get hashCode =>
      kdf.hashCode ^ argon2Config.hashCode ^ pbkdf2Config.hashCode;
}

enum CryptKDF {
  argon2('argon2', 'Argon2'),
  pbkdf2('pbkdf2', 'PBKDF2');

  final String name;
  final String descriptor;

  const CryptKDF(this.name, this.descriptor);

  static CryptKDF fromString(String s) {
    return switch (s) {
      'argon2' => .argon2,
      'pbkdf2' => .pbkdf2,
      _ => .argon2,
    };
  }
}

class Argon2Config {
  final int memory;
  final int parallelism;
  final int iterations;

  const Argon2Config({
    required this.memory,
    required this.parallelism,
    required this.iterations,
  });

  const Argon2Config.defaults()
    : this(memory: 16, parallelism: 2, iterations: 4);

  factory Argon2Config.fromMap(Map<String, dynamic> data) {
    return Argon2Config(
      memory: data['memory'],
      parallelism: data['parallelism'],
      iterations: data['iterations'],
    );
  }

  Map<String, dynamic> toMap() => {
    'memory': memory,
    'parallelism': parallelism,
    'iterations': iterations,
  };

  String get description => 'm=$memory,p=$parallelism,t=$iterations';

  @override
  String toString() =>
      'Argon2Config(memory: $memory, parallelism: $parallelism, iterations: $iterations)';

  @override
  bool operator ==(covariant Argon2Config other) {
    if (identical(this, other)) return true;

    return other.memory == memory &&
        other.parallelism == parallelism &&
        other.iterations == iterations;
  }

  @override
  int get hashCode =>
      memory.hashCode ^ parallelism.hashCode ^ iterations.hashCode;
}

class Pbkdf2Config {
  final int iterations;
  final HashFunction function;

  const Pbkdf2Config({required this.iterations, required this.function});

  const Pbkdf2Config.defaults()
    : this(iterations: 600_000, function: HashFunction.sha256);

  factory Pbkdf2Config.fromMap(Map<String, dynamic> data) {
    return Pbkdf2Config(
      iterations: data['iterations'],
      function: HashFunction.fromSring(data['function']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'function': function.name, 'iterations': iterations};
  }

  String get description => '${function.descriptor} - $iterations iterations';

  @override
  String toString() => 'Pbkdf2Config(iterations: $iterations, hash: $function)';

  @override
  bool operator ==(covariant Pbkdf2Config other) {
    if (identical(this, other)) return true;

    return other.iterations == iterations && other.function == function;
  }

  @override
  int get hashCode => iterations.hashCode ^ function.hashCode;
}

enum HashFunction {
  sha1('sha-1', 'SHA-1'),
  sha256('sha-256', 'SHA-256'),
  sha512('sha-512', 'SHA-512');

  final String name;
  final String descriptor;

  const HashFunction(this.name, this.descriptor);

  static HashFunction fromSring(String s) {
    for (final h in HashFunction.values) {
      if (h.name == s) {
        return h;
      }
    }
    return .sha256;
  }
}

class LdapConfig {
  final String url;
  final bool starttls;
  final bool autoCreateUsers;
  final bool useFilter;
  final String dnTemplate;
  final String bindDn;
  final String bindPassword;
  final String baseDn;
  final String filterTemplate;

  const LdapConfig({
    required this.url,
    required this.starttls,
    required this.autoCreateUsers,
    required this.useFilter,
    required this.dnTemplate,
    required this.bindDn,
    required this.bindPassword,
    required this.baseDn,
    required this.filterTemplate,
  });

  const LdapConfig.defaults()
    : this(
        url: '',
        starttls: false,
        autoCreateUsers: false,
        useFilter: false,
        dnTemplate: '',
        bindDn: '',
        bindPassword: '',
        baseDn: '',
        filterTemplate: '',
      );

  factory LdapConfig.fromMap(Map<String, dynamic> data) {
    return LdapConfig(
      url: data['url'] ?? '',
      starttls: data['starttls'] ?? false,
      autoCreateUsers: data['auto_create_users'] ?? false,
      useFilter: data['use_filter'] ?? false,
      dnTemplate: data['dn_template'] ?? '',
      bindDn: data['filter']?['bind_dn'] ?? '',
      bindPassword: data['filter']?['bind_password'] ?? '',
      baseDn: data['filter']?['base_dn'] ?? '',
      filterTemplate: data['filter']?['template'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'url': url,
      'starttls': starttls,
      'autoCreateUsers': autoCreateUsers,
      'useFilter': useFilter,
      'dnTemplate': dnTemplate,
      'bindDn': bindDn,
      'bindPassword': bindPassword,
      'baseDn': baseDn,
      'filterTemplate': filterTemplate,
    };
  }

  @override
  String toString() {
    return 'LdapConfig(url: $url, starttls: $starttls, autoCreateUsers: $autoCreateUsers, useFilter: $useFilter, dnTemplate: $dnTemplate, bindDn: $bindDn, bindPassword: $bindPassword, baseDn: $baseDn, filterTemplate: $filterTemplate)';
  }

  LdapConfig copyWith({
    String? url,
    bool? starttls,
    bool? autoCreateUsers,
    bool? useFilter,
    String? dnTemplate,
    String? bindDn,
    String? bindPassword,
    String? baseDn,
    String? filterTemplate,
  }) {
    return LdapConfig(
      url: url ?? this.url,
      starttls: starttls ?? this.starttls,
      autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
      useFilter: useFilter ?? this.useFilter,
      dnTemplate: dnTemplate ?? this.dnTemplate,
      bindDn: bindDn ?? this.bindDn,
      bindPassword: bindPassword ?? this.bindPassword,
      baseDn: baseDn ?? this.baseDn,
      filterTemplate: filterTemplate ?? this.filterTemplate,
    );
  }

  @override
  bool operator ==(covariant LdapConfig other) {
    if (identical(this, other)) return true;

    return other.url == url &&
        other.starttls == starttls &&
        other.autoCreateUsers == autoCreateUsers &&
        other.useFilter == useFilter &&
        other.dnTemplate == dnTemplate &&
        other.bindDn == bindDn &&
        other.bindPassword == bindPassword &&
        other.baseDn == baseDn &&
        other.filterTemplate == filterTemplate;
  }

  @override
  int get hashCode {
    return url.hashCode ^
        starttls.hashCode ^
        autoCreateUsers.hashCode ^
        useFilter.hashCode ^
        dnTemplate.hashCode ^
        bindDn.hashCode ^
        bindPassword.hashCode ^
        baseDn.hashCode ^
        filterTemplate.hashCode;
  }
}

class OpenIDConfig {
  final String name;
  final String issuerUrl;
  final String clientId;
  final String clientSecret;
  final bool allowUnverifiedEmails;
  final bool autoCreateUsers;

  OpenIDConfig({
    required this.name,
    required this.issuerUrl,
    required this.clientId,
    required this.clientSecret,
    required this.allowUnverifiedEmails,
    required this.autoCreateUsers,
  });

  OpenIDConfig.empty()
    : this(
        name: '',
        issuerUrl: '',
        clientId: '',
        clientSecret: '',
        allowUnverifiedEmails: false,
        autoCreateUsers: false,
      );

  factory OpenIDConfig.fromMap(String id, Map<String, dynamic> data) {
    return OpenIDConfig(
      name: data['name'],
      issuerUrl: data['issuer_url'],
      clientId: data['client_id'],
      clientSecret: data['client_secret'],
      allowUnverifiedEmails: data['allow_unverified_emails'],
      autoCreateUsers: data['auto_create_users'],
    );
  }

  OpenIDConfig copyWith({
    String? name,
    String? issuerUrl,
    String? clientId,
    String? clientSecret,
    bool? allowUnverifiedEmails,
    bool? autoCreateUsers,
  }) => OpenIDConfig(
    name: name ?? this.name,
    issuerUrl: issuerUrl ?? this.issuerUrl,
    clientId: clientId ?? this.clientId,
    clientSecret: clientSecret ?? this.clientSecret,
    allowUnverifiedEmails: allowUnverifiedEmails ?? this.allowUnverifiedEmails,
    autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
  );

  Map<String, dynamic> toMapDiff(OpenIDConfig old) => {
    if (name != old.name) 'name': name,
    if (issuerUrl != old.issuerUrl) 'issuer_url': issuerUrl,
    if (clientId != old.clientId) 'client_id': clientId,
    if (clientSecret != old.clientSecret) 'client_secret': clientSecret,
    if (allowUnverifiedEmails != old.allowUnverifiedEmails)
      'allow_unverified_emails': allowUnverifiedEmails,
    if (autoCreateUsers != old.autoCreateUsers)
      'auto_create_users': autoCreateUsers,
  };

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'issuerUrl': issuerUrl,
      'clientId': clientId,
      'clientSecret': clientSecret,
      'allowUnverifiedEmails': allowUnverifiedEmails,
      'autoCreateUsers': autoCreateUsers,
    };
  }

  @override
  String toString() {
    return 'OpenIDConfig(name: $name, issuerUrl: $issuerUrl, clientId: $clientId, clientSecret: $clientSecret, allowUnverifiedEmails: $allowUnverifiedEmails, autoCreateUsers: $autoCreateUsers)';
  }

  @override
  bool operator ==(covariant OpenIDConfig other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.issuerUrl == issuerUrl &&
        other.clientId == clientId &&
        other.clientSecret == clientSecret &&
        other.allowUnverifiedEmails == allowUnverifiedEmails &&
        other.autoCreateUsers == autoCreateUsers;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      issuerUrl.hashCode ^
      clientId.hashCode ^
      clientSecret.hashCode ^
      allowUnverifiedEmails.hashCode ^
      autoCreateUsers.hashCode;
}
