import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/setup/setup_mail_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:uri/uri.dart';

class SetupAuthFragment extends StatelessWidget {
  final String instanceUrl;
  const SetupAuthFragment({super.key, required this.instanceUrl});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AuthConfig>();
    final mailEnabled = context.select<MailConfig, bool>((config) => config.enabled);
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
            value: config.passwordConfig != null,
            onChanged: (value) async {
              if (value == true) {
                final passwordConfig = await configurePasswordAuth(context);
                if (passwordConfig != null && context.mounted) {
                  context.read<AuthController>().passwordConfig = passwordConfig;
                }
              } else {
                context.read<AuthController>().passwordConfig = null;
              }
            },
            title: Text('Enable Password Login'),
            subtitle: config.passwordConfig != null ? Text(config.passwordConfig.toString()) : null,
          ),
          CheckboxListTile(
            value: mailEnabled && config.passwordlessLoginEnabled,
            enabled: mailEnabled,
            onChanged: (value) => context.read<AuthController>().passwordlessLoginEnabled = value ?? false,
            title: Text('Enable Passwordless Login'),
            subtitle: mailEnabled ? null : Text('Requires email setup'),
          ),
          ListTile(
            dense: true,
            title: Text('OpenID', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...config.openIdConfigs.mapIndexed((i, cfg) => ListTile(
                title: Text(cfg.name),
                subtitle: Text(cfg.issuerUrl),
                trailing: IconButton(
                    onPressed: () => context.read<AuthController>().removeOpenIDConfig(cfg), icon: Icon(Icons.delete)),
              )),
          TextButton.icon(
            onPressed: () async {
              final openIDConfig = await createOpenIdConfig(context);
              if (openIDConfig == null || !context.mounted) return;
              final re = RegExp(r'[^a-z0-9]+');
              final id = openIDConfig.name.toLowerCase().replaceAll(re, '-');
              context.read<AuthController>().addOpenIDConfig(openIDConfig.copyWith(id: id));
            },
            label: Text('Add OpenID Client Config'),
            icon: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<OpenIDConfig?> createOpenIdConfig(BuildContext context) async {
    String name = '';
    String issuerUrl = '';
    String clientId = '';
    String clientSecret = '';
    bool allowUnverifiedEmails = false;
    bool autoCreateUsers = false;
    return showDialog<OpenIDConfig>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text('OpenID Client Configuration'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(label: Text('Name'), hint: Text('Authelia')),
                      autofocus: true,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.words,
                      initialValue: name,
                      onChanged: (value) => setState(() => name = value),
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(label: Text('Issuer URL'), hint: Text('https://auth.example.com')),
                      keyboardType: TextInputType.url,
                      initialValue: issuerUrl,
                      onChanged: (value) => setState(() => issuerUrl = value),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(label: Text('Client ID'), hint: Text('phylum')),
                      initialValue: clientId,
                      onChanged: (value) => setState(() => clientId = value),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(label: Text('Client Secret')),
                      obscureText: true,
                      initialValue: clientSecret,
                      onChanged: (value) => setState(() => clientSecret = value),
                    ),
                    CheckboxListTile(
                      value: allowUnverifiedEmails,
                      title: Text('Allow Unverified Emails'),
                      subtitle: Text('Use with caution'),
                      onChanged: (value) => setState(() => allowUnverifiedEmails = value ?? false),
                    ),
                    CheckboxListTile(
                      value: autoCreateUsers,
                      title: Text('Automatically Create Users'),
                      subtitle: Text('Only use with trusted private providers'),
                      onChanged: (value) => setState(() => autoCreateUsers = value ?? false),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(OpenIDConfig(
                            name: name,
                            issuerUrl: issuerUrl,
                            clientId: clientId,
                            clientSecret: clientSecret,
                            allowUnverifiedEmails: allowUnverifiedEmails,
                            autoCreateUsers: autoCreateUsers,
                          )),
                      child: Text('OK')),
                ],
              ),
            ));
  }

  Future<PasswordConfig?> configurePasswordAuth(BuildContext context) async {
    final backend = await showOptionsDialog(
      context,
      titleText: 'Select Password Authentication Backend',
      [PasswordBackend.crypt, PasswordBackend.ldap],
      (item) => ListTile(title: Text(item.descriptor)),
    );
    if (backend == null || !context.mounted) return null;
    if (backend == PasswordBackend.crypt) {
      final kdf = await showOptionsDialog(
        context,
        titleText: 'Select Password KDF',
        [CryptKDF.argon2, CryptKDF.pbkdf2],
        (item) => ListTile(title: Text(item.descriptor)),
      );
      if (kdf == null || !context.mounted) return null;
      if (kdf == CryptKDF.argon2) {
        final argon2Config = await configureArgon2(context);
        if (argon2Config == null) {
          return null;
        } else {
          if (context.mounted) {
            context.read<AuthController>().passwordConfig =
                PasswordConfig(cryptConfig: CryptConfig(argon2Config: argon2Config));
          }
        }
      } else if (kdf == CryptKDF.pbkdf2) {
        final pbkdf2Config = await configurePbkdf2(context);
        if (pbkdf2Config == null) {
          return null;
        } else {
          if (context.mounted) {
            context.read<AuthController>().passwordConfig =
                PasswordConfig(cryptConfig: CryptConfig(pbkdf2Config: pbkdf2Config));
          }
        }
      }
    } else if (backend == PasswordBackend.ldap) {
      final ldapConfig = await configureLdap(context);
      if (ldapConfig == null) {
        return null;
      } else {
        if (context.mounted) {
          context.read<AuthController>().passwordConfig = PasswordConfig(ldapConfig: ldapConfig);
        }
      }
    }
    return null;
  }

  Future<LdapConfig?> configureLdap(BuildContext context) async {
    final config = context.read<AuthConfig>().passwordConfig?.ldapConfig ?? LdapConfig.defaults();
    String url = config.url;
    bool starttls = config.starttls;
    bool autoCreateUsers = config.useFilter;
    bool useFilter = config.useFilter;
    String dnTemplate = config.dnTemplate;
    String bindDn = config.bindDn;
    String bindPassword = config.bindDn;
    String baseDn = config.baseDn;
    String filterTemplate = config.filterTemplate;
    return showDialog<LdapConfig>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text('LDAP Configuration'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                          label: Text('LDAP Server URL'), hint: Text('ldap://ldap.example.com:389')),
                      keyboardType: TextInputType.url,
                      initialValue: url,
                      onChanged: (value) => setState(() => url = value),
                    ),
                    CheckboxListTile(
                      value: starttls,
                      title: Text('Use STARTTLS'),
                      onChanged: (value) => setState(() => starttls = value ?? false),
                    ),
                    CheckboxListTile(
                      value: autoCreateUsers,
                      title: Text('Automatically Create Users'),
                      onChanged: (value) => setState(() => autoCreateUsers = value ?? false),
                    ),
                    CheckboxListTile(
                      value: useFilter,
                      title: Text('Use Filter'),
                      onChanged: (value) => setState(() => useFilter = value ?? false),
                    ),
                    if (useFilter)
                      TextFormField(
                        decoration: const InputDecoration(
                            label: Text('DN Template'), hint: Text('uid={email},ou=people,dc=example,dc=com')),
                        initialValue: dnTemplate,
                        key: ValueKey('dn_template'),
                        onChanged: (value) => setState(() => dnTemplate = value),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                                label: Text('Bind DN'), hint: Text('uid=phylum,ou=people,dc=example,dc=com')),
                            initialValue: bindDn,
                            key: ValueKey('bind_dn'),
                            onChanged: (value) => setState(() => bindDn = value),
                          ),
                          TextFormField(
                            decoration: const InputDecoration(label: Text('Bind Password')),
                            initialValue: bindPassword,
                            obscureText: true,
                            key: ValueKey('bind_password'),
                            onChanged: (value) => setState(() => bindPassword = value),
                          ),
                          TextFormField(
                            decoration: const InputDecoration(label: Text('Base DN'), hint: Text('dc=example,dc=com')),
                            initialValue: bindDn,
                            key: ValueKey('base_dn'),
                            onChanged: (value) => setState(() => baseDn = value),
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(label: Text('Filter Template'), hint: Text('(mail={email})')),
                            initialValue: filterTemplate,
                            key: ValueKey('filter_template'),
                            onChanged: (value) => setState(() => filterTemplate = value),
                          ),
                        ],
                      ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(LdapConfig(
                            url: url,
                            starttls: starttls,
                            autoCreateUsers: autoCreateUsers,
                            useFilter: useFilter,
                            dnTemplate: dnTemplate,
                            bindDn: bindDn,
                            bindPassword: bindPassword,
                            baseDn: baseDn,
                            filterTemplate: filterTemplate,
                          )),
                      child: Text('OK')),
                ],
              ),
            ));
  }

  Future<Argon2Config?> configureArgon2(BuildContext context) async {
    final config = context.read<AuthConfig>().passwordConfig?.cryptConfig?.argon2Config ?? Argon2Config.defaults();
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
                    ElevatedButton(onPressed: () => testArgon2Params(context, m, t, p), child: Text('Test Parameters'))
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

  Future<void> testArgon2Params(BuildContext context, int memory, int iterations, int parallelism) async {
    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/auth/test_argon2_params';
    builder.queryParameters = {
      "memory": memory.toString(),
      "iterations": iterations.toString(),
      "parallelism": parallelism.toString(),
    };
    final request = Request('get', builder.build());

    final responseString = await sendRequest(context, 'Testing Argon2 Params', request);
    if (responseString == null || !context.mounted) return;
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

  Future<Pbkdf2Config?> configurePbkdf2(BuildContext context) async {
    final config = context.read<AuthConfig>().passwordConfig?.cryptConfig?.pbkdf2Config ?? Pbkdf2Config.defaults();
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
                          min: 200000,
                          max: 4000000,
                          divisionsFactor: 200000,
                        );
                        if (input != null) {
                          setState(() => iterations = input);
                        }
                      },
                    ),
                    ElevatedButton(
                        onPressed: () => testPbkdf2Params(context, hash, iterations), child: Text('Test Parameters'))
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

  Future<void> testPbkdf2Params(BuildContext context, HashFunction hash, int iterations) async {
    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/auth/test_pbkdf2_params';
    builder.queryParameters = {
      "function": hash.name,
      "iterations": iterations.toString(),
    };
    final request = Request('get', builder.build());

    final responseString = await sendRequest(context, 'Testing PBKDF2 Params', request);
    if (responseString == null || !context.mounted) return;
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
      await showAlertDialog(context, title: 'Could not test PBKDF2 params', message: "${responseMap["error"]}");
    }
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

class AuthController extends StateNotifier<AuthConfig> {
  AuthController() : super(AuthConfig.defaults());

  set passwordConfig(PasswordConfig? config) {
    state = state.copyWith(passwordConfig: config, updatePasswordConfig: true);
  }

  set passwordlessLoginEnabled(bool enabled) {
    state = state.copyWith(passwordlessLoginEnabled: enabled);
  }

  void addOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(openIdConfigs: [...state.openIdConfigs, config].toList(growable: false));
  }

  void removeOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(openIdConfigs: state.openIdConfigs.whereNot((e) => e == config).toList(growable: false));
  }
}

class AuthConfig {
  final PasswordConfig? passwordConfig;
  final bool passwordlessLoginEnabled;
  final List<OpenIDConfig> openIdConfigs;

  const AuthConfig({
    required this.passwordConfig,
    required this.passwordlessLoginEnabled,
    required this.openIdConfigs,
  });

  const AuthConfig.defaults()
      : this(
          passwordConfig: null,
          passwordlessLoginEnabled: false,
          openIdConfigs: const [],
        );

  bool get valid => passwordConfig != null || passwordlessLoginEnabled || openIdConfigs.isNotEmpty;

  AuthConfig copyWith({
    PasswordConfig? passwordConfig,
    bool updatePasswordConfig = false,
    bool? passwordlessLoginEnabled,
    List<OpenIDConfig>? openIdConfigs,
  }) {
    return AuthConfig(
      passwordConfig: updatePasswordConfig ? passwordConfig : this.passwordConfig,
      passwordlessLoginEnabled: passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
      openIdConfigs: openIdConfigs ?? this.openIdConfigs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'password': {
        'backend': 'none',
        ...?passwordConfig?.toMap(),
      },
      'magic_links': passwordlessLoginEnabled,
      'openid': const {},
    };
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

  OpenIDConfig copyWith({
    String? id,
    String? name,
    String? issuerUrl,
    String? clientId,
    String? clientSecret,
    bool? allowUnverifiedEmails,
    bool? autoCreateUsers,
  }) =>
      OpenIDConfig(
        name: name ?? this.name,
        issuerUrl: issuerUrl ?? this.issuerUrl,
        clientId: clientId ?? this.clientId,
        clientSecret: clientSecret ?? this.clientSecret,
        allowUnverifiedEmails: allowUnverifiedEmails ?? this.allowUnverifiedEmails,
        autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
      );
}

class PasswordConfig {
  final CryptConfig? cryptConfig;
  final LdapConfig? ldapConfig;

  const PasswordConfig({this.cryptConfig, this.ldapConfig}) : assert((cryptConfig == null) != (ldapConfig == null));

  Map<String, dynamic> toMap() {
    if (cryptConfig != null) {
      return {
        'backend': 'crypt',
        'crypt': cryptConfig!.toMap(),
      };
    } else if (ldapConfig != null) {
      return {
        'backend': 'ldap',
        'ldap': ldapConfig!.toMap(),
      };
    }
    return {};
  }

  @override
  String toString() {
    if (cryptConfig != null) {
      return 'DB ($cryptConfig)';
    } else if (ldapConfig != null) {
      return 'LDAP ($ldapConfig)';
    }
    return 'Unknown';
  }
}

class CryptConfig {
  final Argon2Config? argon2Config;
  final Pbkdf2Config? pbkdf2Config;

  const CryptConfig({this.argon2Config, this.pbkdf2Config}) : assert((argon2Config == null) != (pbkdf2Config == null));

  Map<String, dynamic> toMap() {
    if (argon2Config != null) {
      return {
        'kdf': 'argon2',
        'argon2': argon2Config!.toMap(),
      };
    } else if (pbkdf2Config != null) {
      return {
        'kdf': 'pbkdf2',
        'pbkdf2': pbkdf2Config!.toMap(),
      };
    }
    return {};
  }

  @override
  String toString() {
    if (argon2Config != null) {
      return 'Argon2 $argon2Config';
    } else if (pbkdf2Config != null) {
      return 'PBKDF2 $pbkdf2Config';
    }
    return 'Unknown';
  }
}

class Argon2Config {
  final int memory;
  final int parallelism;
  final int iterations;

  const Argon2Config({required this.memory, required this.parallelism, required this.iterations});

  const Argon2Config.defaults() : this(memory: 16, parallelism: 2, iterations: 4);

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

  const Pbkdf2Config.defaults() : this(iterations: 600_000, hash: HashFunction.sha256);

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

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'starttls': starttls,
      'auto_create_users': autoCreateUsers,
      'use_filter': useFilter,
      'dn_template': dnTemplate,
      'bind_dn': bindDn,
      'bind_password': bindPassword,
      'base_dn': baseDn,
      'filter_template': filterTemplate,
    };
  }

  @override
  String toString() {
    return url;
  }
}
