import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/setup/setup_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

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
            subtitle: config.passwordLoginEnabled ? Text(config.passwordConfig.toString()) : null,
          ),
          CheckboxListTile(
            value: widget.mailEnabled && config.passwordlessLoginEnabled,
            enabled: widget.mailEnabled,
            onChanged: (value) => setState(() => config = config.copyWith(passwordlessLoginEnabled: value ?? false)),
            title: Text('Enable Passwordless Login'),
          ),
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
      } else if (kdf == CryptKDF.pbkdf2) {
        final pbkdf2Config = await configurePbkdf2(config.passwordConfig.cryptConfig.pbkdf2Config);
        if (pbkdf2Config == null) {
          return null;
        } else {
          return config.passwordConfig.copyWith(
            backend: PasswordBackend.crypt,
            cryptConfig: config.passwordConfig.cryptConfig.copyWith(
              kdf: CryptKDF.pbkdf2,
              pbkdf2Config: pbkdf2Config,
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
                      subtitle: Text('$m - ${pow(2, m + 10).toInt().formatForDisplay(noDecimal: true)}'),
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
                    ElevatedButton(onPressed: () => testArgon2Params(m, t, p), child: Text('Test Parameters'))
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

  Future<void> testArgon2Params(int memory, int iterations, int parallelism) async {
    final builder = UriBuilder.fromUri(Uri.parse(widget.instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/auth/test_argon2_params';
    builder.queryParameters = {
      "memory": memory.toString(),
      "iterations": iterations.toString(),
      "parallelism": parallelism.toString(),
    };
    final request = Request('get', builder.build());

    final responseString = await sendRequest(context, 'Testing Argon2 Params', request);
    if (responseString == null || !mounted) return;
    final responseMap = (jsonDecode(responseString) as Map).cast<String, dynamic>();

    if (responseMap["success"]) {
      final time = Duration(microseconds: responseMap["time"]);
      await showAlertDialog(
        context,
        title: 'Took ${time.inMilliseconds > 5 ? '${time.inMilliseconds}ms' : '${time.inMicroseconds}us'}',
        message: time.inMilliseconds < 300
            ? 'You should aim to take at least 300ms.'
            : time.inMilliseconds > 1000
                ? 'That\'s a long time. Consider lowering the number of iterations.'
                : 'Looks good!',
      );
    } else {
      await showAlertDialog(context, title: 'Could not test argon2 params', message: "${responseMap["error"]}");
    }
  }

  Future<Pbkdf2Config?> configurePbkdf2(Pbkdf2Config config) async {
    var iterations = config.iterations;
    var hash = config.hash;
    return showDialog<Pbkdf2Config>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text('PBKDF2 Parameters'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Hash Function'),
                      subtitle: Text(hash.descriptor),
                      onTap: () async {
                        final input = await showOptionsDialog(
                          context,
                          [HashFunction.sha1, HashFunction.sha256, HashFunction.sha512],
                          (item) => ListTile(title: Text(item.descriptor)),
                        );
                        if (input != null) {
                          setState(() => hash = input);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Iterations'),
                      subtitle: Text(iterations.toString()),
                      onTap: () async {
                        final input = await showIntSliderDialog(
                          context,
                          title: 'Iterations',
                          value: iterations,
                          min: 100000,
                          max: 1000000,
                          divisionsFactor: 100000,
                        );
                        if (input != null) {
                          setState(() => iterations = input);
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(Pbkdf2Config(hash: hash, iterations: iterations)),
                      child: Text('OK')),
                ],
              ),
            ));
  }

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
                pbkdf2Config: Pbkdf2Config(iterations: 500000, hash: HashFunction.sha256),
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

  String toString() {
    return switch (backend) {
      PasswordBackend.crypt => 'DB ($cryptConfig)',
      PasswordBackend.ldap => 'LDAP ($ldapConfig)',
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

  String toString() {
    return switch (kdf) {
      CryptKDF.argon2 => 'Argon2 $argon2Config',
      CryptKDF.pbkdf2 => 'PBKDF2 $pbkdf2Config',
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

  @override
  String toString() {
    return 'm=$memory,t=$iterations,p=$parallelism';
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

  @override
  String toString() {
    return 'hash=${hash.descriptor},iterations=$iterations';
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
