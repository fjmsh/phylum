class AuthConfig {
  final bool passwordlessLoginEnabled;
  final PasswordConfig passwordConfig;
  final List<OpenIDConfig> openIdConfigs;

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
        openIdConfigs: const [],
      );

  bool get valid =>
      passwordConfig.backend != PasswordBackend.none ||
      passwordlessLoginEnabled ||
      openIdConfigs.isNotEmpty;

  AuthConfig copyWith({
    PasswordConfig? passwordConfig,
    bool? passwordlessLoginEnabled,
    List<OpenIDConfig>? openIdConfigs,
  }) {
    final re = RegExp(r'[^a-z0-9]+');
    if (openIdConfigs != null) {
      for (final c in openIdConfigs) {
        if (c.id == '') {
          final originalId = c.name.toLowerCase().replaceAll(re, '-');
          String id = originalId;
          int i = 2;
          while (openIdConfigs.any((e) => e.id == id)) {
            id = '$originalId-$i';
            i++;
          }
          c._id = id;
        }
      }
    }
    return AuthConfig(
      passwordlessLoginEnabled:
          passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
      passwordConfig: passwordConfig ?? this.passwordConfig,
      openIdConfigs: openIdConfigs ?? this.openIdConfigs,
    );
  }

  factory AuthConfig.fromMap(Map<String, dynamic> data) {
    final clients = data['openid']?['clients'];
    return AuthConfig(
      passwordlessLoginEnabled: data['magic_links'],
      passwordConfig: data.containsKey('password')
          ? PasswordConfig.fromMap((data['password'] as Map).cast())
          : PasswordConfig.defaults(),
      openIdConfigs: clients == null
          ? const []
          : (clients as Map)
                .cast<String, dynamic>()
                .entries
                .map<OpenIDConfig>(
                  (e) => OpenIDConfig.fromMap(e.key, (e.value as Map).cast()),
                )
                .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() {
    final clients = <String, dynamic>{};
    for (final config in openIdConfigs) {
      assert(config.id != '');
      clients[config.id] = config.toMap();
    }
    return {
      if (passwordLoginEnabled) 'password': passwordConfig.toMap(),
      if (passwordlessLoginEnabled) 'magic_links': passwordlessLoginEnabled,
      if (clients.isNotEmpty) 'openid': {'clients': clients},
    };
  }
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
      .none => {'backend': 'crypt'},
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
}

enum PasswordBackend {
  none('none', 'None'),
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
  String toString() => switch (kdf) {
    CryptKDF.argon2 => 'Argon2 ($argon2Config)',
    CryptKDF.pbkdf2 => 'PBKDF2 ($pbkdf2Config)',
  };
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

  Map<String, dynamic> toMap() {
    return {
      'memory': memory,
      'parallelism': parallelism,
      'iterations': iterations,
    };
  }

  @override
  String toString() {
    return 'm=$memory,t=$iterations,p=$parallelism';
  }
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
    return {'hash': function.name, 'iterations': iterations};
  }

  @override
  String toString() {
    return 'hash=${function.descriptor},iterations=$iterations';
  }
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
        starttls: true,
        autoCreateUsers: false,
        useFilter: false,
        dnTemplate: '',
        bindDn: '',
        bindPassword: '',
        baseDn: '',
        filterTemplate: '(mail={email})',
      );

  factory LdapConfig.fromMap(Map<String, dynamic> data) {
    return LdapConfig(
      url: data['url'] ?? '',
      starttls: data['starttls'] ?? '',
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
    return {
      'url': url,
      'starttls': starttls,
      'use_filter': useFilter,
      'dn_template': dnTemplate,
      if (useFilter)
        'filter': {
          'bind_dn': bindDn,
          'bind_password': bindPassword,
          'base_dn': baseDn,
          'template': filterTemplate,
        },
      'auto_create_users': autoCreateUsers,
    };
  }

  @override
  String toString() {
    return url;
  }
}

class OpenIDConfig {
  String _id;
  String get id => _id;
  final String name;
  final String issuerUrl;
  final String clientId;
  final String clientSecret;
  final bool allowUnverifiedEmails;
  final bool autoCreateUsers;

  OpenIDConfig({
    required this._id,
    required this.name,
    required this.issuerUrl,
    required this.clientId,
    required this.clientSecret,
    required this.allowUnverifiedEmails,
    required this.autoCreateUsers,
  });

  OpenIDConfig.empty()
    : this(
        id: '',
        name: '',
        issuerUrl: '',
        clientId: '',
        clientSecret: '',
        allowUnverifiedEmails: false,
        autoCreateUsers: false,
      );

  factory OpenIDConfig.fromMap(String id, Map<String, dynamic> data) {
    return OpenIDConfig(
      id: id,
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
    id: id,
    name: name ?? this.name,
    issuerUrl: issuerUrl ?? this.issuerUrl,
    clientId: clientId ?? this.clientId,
    clientSecret: clientSecret ?? this.clientSecret,
    allowUnverifiedEmails: allowUnverifiedEmails ?? this.allowUnverifiedEmails,
    autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'issuer_url': issuerUrl,
    'client_id': clientId,
    'client_secret': clientSecret,
    'allow_unverified_emails': allowUnverifiedEmails,
    'auto_create_users': autoCreateUsers,
  };
}
