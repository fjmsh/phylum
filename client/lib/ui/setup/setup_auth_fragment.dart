import 'dart:math';

import 'package:flutter/material.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/setup/setup_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';

class SetupAuthFragment extends SetupFragment<SetupAuthFragment> {
  final String instanceUrl;
  final AuthConfig config;
  final bool mailEnabled;

  const SetupAuthFragment({super.key, required this.instanceUrl, required this.config, required this.mailEnabled});

  @override
  SetupFragmentState<SetupAuthFragment> createState() => SetupAuthFragmentState();
}

class SetupAuthFragmentState extends SetupFragmentState<SetupAuthFragment> {
  late AuthConfig config;

  @override
  void initState() {
    super.initState();
    config = widget.config;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12.0,
        children: [
          Text(
            'Auth',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          CheckboxListTile(
            value: config.passwordLoginEnabled,
            onChanged: (value) async {
              if (value == true) {
                final passwordConfig = await configurePasswordAuth();
                if (passwordConfig != null) {
                  setState(() {
                    config = config.copyWith(passwordLoginEnabled: true, passwordConfig: passwordConfig);
                  });
                }
              } else {
                setState(() {
                  config = config.copyWith(passwordLoginEnabled: false);
                });
              }
            },
            title: Text('Enable Password Login'),
            subtitle: config.passwordLoginEnabled ? Text('Backend: ${config.passwordConfig.backend.descriptor}') : null,
          ),
          CheckboxListTile(
            value: widget.mailEnabled && config.passwordlessLoginEnabled,
            enabled: widget.mailEnabled,
            onChanged: (value) => setState(() => config = config.copyWith(passwordlessLoginEnabled: value ?? false)),
            title: Text('Enable Passwordless Login'),
          ),
          // TextField(
          //   decoration: const InputDecoration(label: Text('Host'), hint: Text('localhost')),
          //   autofocus: true,
          //   autocorrect: false,
          //   keyboardType: TextInputType.url,
          //   onChanged: (value) => config.host = value,
          // ),
          // TextField(
          //   decoration: const InputDecoration(label: Text('Port'), hint: Text('5432')),
          //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          //   keyboardType: TextInputType.number,
          //   onChanged: (value) => config.port = int.tryParse(value) ?? 0,
          // ),
          // TextField(
          //   decoration: const InputDecoration(label: Text('Database Name'), hint: Text('phylum')),
          //   autocorrect: false,
          //   onChanged: (value) => config.name = value,
          // ),
          // TextField(
          //   decoration: const InputDecoration(label: Text('User'), hint: Text('phylum')),
          //   autocorrect: false,
          //   onChanged: (value) => config.user = value,
          // ),
          // TextField(
          //   decoration: const InputDecoration(label: Text('Password')),
          //   autocorrect: false,
          //   obscureText: true,
          //   onChanged: (value) => config.password = value,
          // ),
        ],
      ),
    );
  }

  Future<PasswordConfig?> configurePasswordAuth() async {
    final backend = await showOptionsDialog(
      context,
      titleText: 'Select Password Authentication Backend',
      [PasswordBackend.crypt, PasswordBackend.ldap],
      (item) => ListTile(title: Text(item.descriptor)),
    );
    if (backend == null || !mounted) return null;
    if (backend == PasswordBackend.crypt) {
      final kdf = await showOptionsDialog(
        context,
        titleText: 'Select Password KDF',
        [CryptKDF.argon2, CryptKDF.pbkdf2],
        (item) => ListTile(title: Text(item.descriptor)),
      );
      if (kdf == null || !mounted) return null;
      if (kdf == CryptKDF.argon2) {
        final argon2Config = await configureArgon2(config.passwordConfig.cryptConfig.argon2Config);
        print(argon2Config);
        if (argon2Config == null) {
          return null;
        } else {
          return config.passwordConfig.copyWith(
            backend: PasswordBackend.crypt,
            cryptConfig: config.passwordConfig.cryptConfig.copyWith(
              kdf: CryptKDF.argon2,
              argon2Config: argon2Config,
            ),
          );
        }
      }
    } else if (backend == PasswordBackend.ldap) {}
    return null;
  }

  Future<Argon2Config?> configureArgon2(Argon2Config config) async {
    int m = config.memory;
    int p = config.parallelism;
    int t = config.iterations;
    return showDialog<Argon2Config>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text('Argon2 Parameters'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Memory Factor'),
                      subtitle: Text('$m - ${pow(2, m + 10).toInt().formatForDisplay()}'),
                      onTap: () async {
                        final input =
                            await showIntSliderDialog(context, title: 'Memory Factor (m)', value: m, min: 10, max: 24);
                        if (input != null) {
                          setState(() => m = input);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Parallelism'),
                      subtitle: Text(p.toString()),
                      onTap: () async {
                        final input =
                            await showIntSliderDialog(context, title: 'Parallelism (p)', value: p, min: 1, max: 8);
                        if (input != null) {
                          setState(() => p = input);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Iterations'),
                      subtitle: Text(t.toString()),
                      onTap: () async {
                        final input =
                            await showIntSliderDialog(context, title: 'Iterations (t)', value: t, min: 1, max: 20);
                        if (input != null) {
                          setState(() => t = input);
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text('Cancel')),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(Argon2Config(memory: m, parallelism: p, iterations: t)),
                      child: Text('OK')),
                ],
              ),
            ));
  }

  Future<Pbkdf2Config?> configurePbkdf2(Pbkdf2Config? config) async {}

  @override
  bool handleNextPress() {
    return true;
  }
}

enum PasswordBackend {
  crypt('crypt', 'DB'),
  ldap('ldap', 'LDAP');

  final String name;
  final String descriptor;

  const PasswordBackend(this.name, this.descriptor);
}

enum CryptKDF {
  argon2('argon2', 'Argon2'),
  pbkdf2('pbkdf2', 'PBKDF2');

  final String name;
  final String descriptor;

  const CryptKDF(this.name, this.descriptor);
}

class AuthConfig {
  final bool passwordLoginEnabled;
  final bool passwordlessLoginEnabled;
  final PasswordConfig passwordConfig;

  const AuthConfig({
    required this.passwordLoginEnabled,
    required this.passwordlessLoginEnabled,
    required this.passwordConfig,
  });

  const AuthConfig.defaults()
      : this(
            passwordLoginEnabled: false,
            passwordlessLoginEnabled: false,
            passwordConfig: const PasswordConfig(
              backend: PasswordBackend.crypt,
              cryptConfig: CryptConfig(
                kdf: CryptKDF.argon2,
                argon2Config: Argon2Config(memory: 16, parallelism: 2, iterations: 4),
                pbkdf2Config: Pbkdf2Config(iterations: 100000, hash: HashFunction.sha256),
              ),
              ldapConfig: LdapConfig(
                url: '',
                startTls: false,
                useDnTemplate: true,
                dnTemplate: '',
                bindDn: '',
                bindDnPassword: '',
                baseDn: '',
                filterTemplate: '',
              ),
              resetEnabled: true,
            ));

  AuthConfig copyWith({
    bool? passwordLoginEnabled,
    bool? passwordlessLoginEnabled,
    PasswordConfig? passwordConfig,
  }) {
    return AuthConfig(
      passwordLoginEnabled: passwordLoginEnabled ?? this.passwordLoginEnabled,
      passwordlessLoginEnabled: passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
      passwordConfig: passwordConfig ?? this.passwordConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backend': (passwordLoginEnabled) ? passwordConfig.toMap() : 'none',
      'magic_links': passwordlessLoginEnabled,
      'openid': const {},
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
    return {
      'backend': backend.name,
      if (backend == PasswordBackend.crypt) 'crypt': cryptConfig.toMap(),
      if (backend == PasswordBackend.ldap) 'ldap': ldapConfig.toMap(),
    };
  }
}

class CryptConfig {
  final CryptKDF kdf;
  final Argon2Config argon2Config;
  final Pbkdf2Config pbkdf2Config;

  const CryptConfig({required this.kdf, required this.argon2Config, required this.pbkdf2Config});

  CryptConfig copyWith({
    CryptKDF? kdf,
    Argon2Config? argon2Config,
    Pbkdf2Config? pbkdf2Config,
  }) {
    return CryptConfig(
      kdf: kdf ?? this.kdf,
      argon2Config: argon2Config ?? this.argon2Config,
      pbkdf2Config: pbkdf2Config ?? this.pbkdf2Config,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kdf': kdf.name,
      if (kdf == CryptKDF.argon2) 'argon2': argon2Config.toMap(),
      if (kdf == CryptKDF.pbkdf2) 'pbkdf2': pbkdf2Config.toMap(),
    };
  }
}

class Argon2Config {
  final int memory;
  final int parallelism;
  final int iterations;

  const Argon2Config({required this.memory, required this.parallelism, required this.iterations});

  Map<String, dynamic> toMap() {
    return {
      'memory': memory,
      'parallelism': parallelism,
      'iterations': iterations,
    };
  }
}

class Pbkdf2Config {
  final int iterations;
  final HashFunction hash;

  const Pbkdf2Config({required this.iterations, required this.hash});

  const Pbkdf2Config.defaults() : this(iterations: 100000, hash: HashFunction.sha256);

  Map<String, dynamic> toMap() {
    return {
      'hash': hash.name,
      'iterations': iterations,
    };
  }
}

enum HashFunction {
  sha1('sha-1', 'SHA-1'),
  sha256('sha-256', 'SHA-256'),
  sha512('sha-512', 'SHA-512');

  final String name;
  final String descriptor;

  const HashFunction(this.name, this.descriptor);
}

class LdapConfig {
  final String url;
  final bool startTls;
  final bool useDnTemplate;
  final String dnTemplate;
  final String bindDn;
  final String bindDnPassword;
  final String baseDn;
  final String filterTemplate;

  const LdapConfig({
    required this.url,
    required this.startTls,
    required this.useDnTemplate,
    required this.dnTemplate,
    required this.bindDn,
    required this.bindDnPassword,
    required this.baseDn,
    required this.filterTemplate,
  });

  Map<String, dynamic> toMap() {
    if (useDnTemplate) {
      return {
        'url': url,
        'starttls': startTls,
        'dn_template': dnTemplate,
      };
    }
    return {
      'url': url,
      'starttls': startTls,
      'dn_template': '',
      'bind_dn': bindDn,
      'bind_password': bindDnPassword,
      'base_dn': baseDn,
      'filter_template': filterTemplate,
    };
  }
}
