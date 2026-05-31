import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/setup/ldap_dialog.dart';
import 'package:phylum/ui/setup/setup_mail_fragment.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:uri/uri.dart';

class SetupAuthFragment extends StatelessWidget {
  final formKey = GlobalKey<FormState>();
  final String instanceUrl;
  final void Function() onPrevPress;
  final void Function() onNextPress;

  SetupAuthFragment({
    super.key,
    required this.instanceUrl,
    required this.onPrevPress,
    required this.onNextPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: buildContents(context))),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onPrevPress,
                child: Text('PREV'),
              ),
              TextButton(
                onPressed: () => validateAndNext(context),
                child: Text('NEXT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildContents(BuildContext context) {
    final config = context.watch<AuthConfig>();
    final mailEnabled =
        context.select<MailConfig, bool>((config) => config.enabled);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Auth', style: Theme.of(context).textTheme.headlineSmall),
        SwitchListTile(
          title: Text('Enable Passwordless Email Login'),
          subtitle: mailEnabled ? null : Text('Requires Email'),
          secondary: Icon(Icons.email),
          value: mailEnabled && config.passwordlessLoginEnabled,
          onChanged: mailEnabled
              ? (value) => context
                  .read<AuthController>()
                  .passwordlessLoginEnabled = value
              : null,
        ),
        const SizedBox(height: 18),
        ListTile(
          dense: true,
          title: Text('Password Auth',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SwitchListTile(
          title: Text('Enable Password Auth'),
          secondary: Icon(Icons.password),
          value: config.passwordLoginEnabled,
          onChanged: (value) =>
              context.read<AuthController>().passwordLoginEnabled = value,
          // subtitle:
          //     config.passwordConfig != null ? Text(config.toString()) : null,
        ),
        if (config.passwordLoginEnabled)
          buildPasswordAuthSection(context, config.passwordConfig),
        const SizedBox(height: 18),
        ListTile(
          dense: true,
          title: Text('OpenID', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...config.openIdConfigs.mapIndexed((i, cfg) => ListTile(
              title: Text(cfg.name),
              subtitle: Text(cfg.issuerUrl),
              trailing: IconButton(
                  onPressed: () =>
                      context.read<AuthController>().removeOpenIDConfig(cfg),
                  icon: Icon(Icons.delete)),
            )),
        TextButton.icon(
          onPressed: () async {
            final openIDConfig = await createOpenIdConfig(context);
            if (openIDConfig == null || !context.mounted) return;
            final re = RegExp(r'[^a-z0-9]+');
            final id = openIDConfig.name.toLowerCase().replaceAll(re, '-');
            context
                .read<AuthController>()
                .addOpenIDConfig(openIDConfig.copyWith(id: id));
          },
          label: Text('Add OpenID Client Config'),
          icon: Icon(Icons.add),
        ),
      ],
    );
  }

  Widget buildPasswordAuthSection(
    BuildContext context,
    PasswordConfig config,
  ) {
    final mailEnabled =
        context.select<MailConfig, bool>((config) => config.enabled);
    return Column(
      children: [
        ListTile(
          title: Text('Backend'),
          leading: Icon(Icons.storage),
          subtitle: Text(config.backend.descriptor),
          onTap: () async {
            final backend = await showOptionsDialog(
              context,
              titleText: 'Password Auth Backend',
              [PasswordBackend.crypt, PasswordBackend.ldap],
              (item) => ListTile(title: Text(item.descriptor)),
            );
            if (backend == null || !context.mounted) return;

            config = config.copyWith(backend: backend);
            if (backend == PasswordBackend.ldap) {
              final ldapConfig =
                  await LdapConfigDialog.show(context, config.ldapConfig);
              if (ldapConfig == null || !context.mounted) return;
              config = config.copyWith(ldapConfig: ldapConfig);
            }

            context.read<AuthController>().passwordConfig = config;
          },
        ),
        if (config.backend == PasswordBackend.crypt)
          ListTile(
            title: Text('KDF'),
            subtitle: Text(config.cryptConfig.toString()),
            leading: Icon(Icons.key),
            onTap: () => selectKdf(context, config),
          )
        else if (config.backend == PasswordBackend.ldap)
          ListTile(
              title: Text('LDAP Configuration'),
              subtitle: Text(config.ldapConfig.toString()),
              leading: Icon(Icons.key),
              onTap: () async {
                final ldapConfig =
                    await LdapConfigDialog.show(context, config.ldapConfig);
                if (ldapConfig == null || !context.mounted) return;
                config = config.copyWith(ldapConfig: ldapConfig);
              }),
        SwitchListTile(
          title: Text('Password Reset'),
          subtitle: !mailEnabled
              ? const Text('Requires Email')
              : config.backend != PasswordBackend.crypt
                  ? const Text('Only supported for DB backend')
                  : null,
          secondary: Icon(Icons.refresh),
          value: mailEnabled && config.backend == PasswordBackend.crypt
              ? config.resetEnabled
              : false,
          onChanged: mailEnabled && config.backend == PasswordBackend.crypt
              ? (value) => context.read<AuthController>().passwordConfig =
                  config.copyWith(resetEnabled: value)
              : null,
        )
      ],
    );
  }

  void selectKdf(BuildContext context, PasswordConfig config) async {
    final kdf = await showOptionsDialog(
      context,
      titleText: 'Select Password KDF',
      [CryptKDF.argon2, CryptKDF.pbkdf2],
      (item) => ListTile(title: Text(item.descriptor)),
    );
    if (kdf == null || !context.mounted) return;

    CryptConfig? cryptConfig;
    if (kdf == CryptKDF.argon2) {
      final argon2Config = await configureArgon2(
        context,
        config.cryptConfig.argon2Config,
      );
      if (argon2Config != null) {
        cryptConfig = config.cryptConfig.copyWith(
          kdf: CryptKDF.argon2,
          argon2Config: argon2Config,
        );
      }
    } else if (kdf == CryptKDF.pbkdf2) {
      final pbkdf2Config = await configurePbkdf2(
        context,
        config.cryptConfig.pbkdf2Config,
      );
      if (pbkdf2Config != null) {
        cryptConfig = config.cryptConfig.copyWith(
          kdf: CryptKDF.pbkdf2,
          pbkdf2Config: pbkdf2Config,
        );
      }
    }
    if (cryptConfig == null || !context.mounted) return;

    context.read<AuthController>().passwordConfig =
        config.copyWith(cryptConfig: cryptConfig);
  }

  Future<void> validateAndNext(BuildContext context) async {
    if (formKey.currentState?.validate() == false) return;
    onNextPress();
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
                      decoration: const InputDecoration(
                          label: Text('Name'), hint: Text('Authelia')),
                      autofocus: true,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.words,
                      initialValue: name,
                      onChanged: (value) => setState(() => name = value),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                          label: Text('Issuer URL'),
                          hint: Text('https://auth.example.com')),
                      keyboardType: TextInputType.url,
                      initialValue: issuerUrl,
                      onChanged: (value) => setState(() => issuerUrl = value),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                          label: Text('Client ID'), hint: Text('phylum')),
                      initialValue: clientId,
                      onChanged: (value) => setState(() => clientId = value),
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(label: Text('Client Secret')),
                      obscureText: true,
                      initialValue: clientSecret,
                      onChanged: (value) =>
                          setState(() => clientSecret = value),
                    ),
                    CheckboxListTile(
                      value: allowUnverifiedEmails,
                      title: Text('Allow Unverified Emails'),
                      subtitle: Text('Use with caution'),
                      onChanged: (value) => setState(
                          () => allowUnverifiedEmails = value ?? false),
                    ),
                    CheckboxListTile(
                      value: autoCreateUsers,
                      title: Text('Automatically Create Users'),
                      subtitle: Text('Only use with trusted private providers'),
                      onChanged: (value) =>
                          setState(() => autoCreateUsers = value ?? false),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('Cancel')),
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

  Future<Argon2Config?> configureArgon2(
    BuildContext context,
    Argon2Config config,
  ) async {
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
                      subtitle: Text(
                          '$m - ${pow(2, m + 10).toInt().formatForDisplay(noDecimal: true)}'),
                      onTap: () async {
                        final input = await showIntSliderDialog(context,
                            title: 'Memory Factor (m)',
                            value: m,
                            min: 10,
                            max: 24);
                        if (input != null) {
                          setState(() => m = input);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Parallelism'),
                      subtitle: Text(p.toString()),
                      onTap: () async {
                        final input = await showIntSliderDialog(context,
                            title: 'Parallelism (p)', value: p, min: 1, max: 8);
                        if (input != null) {
                          setState(() => p = input);
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Iterations'),
                      subtitle: Text(t.toString()),
                      onTap: () async {
                        final input = await showIntSliderDialog(context,
                            title: 'Iterations (t)', value: t, min: 1, max: 20);
                        if (input != null) {
                          setState(() => t = input);
                        }
                      },
                    ),
                    ElevatedButton(
                        onPressed: () => testArgon2Params(context, m, t, p),
                        child: Text('Test Parameters'))
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(Argon2Config(
                          memory: m, parallelism: p, iterations: t)),
                      child: Text('OK')),
                ],
              ),
            ));
  }

  Future<void> testArgon2Params(
    BuildContext context,
    int memory,
    int iterations,
    int parallelism,
  ) async {
    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/auth/test_argon2_params';
    builder.queryParameters = {
      "memory": memory.toString(),
      "iterations": iterations.toString(),
      "parallelism": parallelism.toString(),
    };
    final request = Request('get', builder.build());

    final responseString =
        await sendRequest(context, 'Testing Argon2 Params', request);
    if (responseString == null || !context.mounted) return;
    final responseMap =
        (jsonDecode(responseString) as Map).cast<String, dynamic>();

    if (responseMap["success"]) {
      final time = Duration(microseconds: responseMap["time"]);
      await showAlertDialog(
        context,
        title:
            'Took ${time.inMilliseconds > 5 ? '${time.inMilliseconds}ms' : '${time.inMicroseconds}us'}',
        message: time.inMilliseconds < 300
            ? 'You should aim to take at least 300ms.'
            : time.inMilliseconds > 1000
                ? 'That\'s a long time. Consider lowering the number of iterations.'
                : 'Looks good!',
      );
    } else {
      await showAlertDialog(context,
          title: 'Could not test argon2 params',
          message: "${responseMap["error"]}");
    }
  }

  Future<Pbkdf2Config?> configurePbkdf2(
    BuildContext context,
    Pbkdf2Config config,
  ) async {
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
                          [
                            HashFunction.sha1,
                            HashFunction.sha256,
                            HashFunction.sha512
                          ],
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
                        onPressed: () =>
                            testPbkdf2Params(context, hash, iterations),
                        child: Text('Test Parameters'))
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(
                          Pbkdf2Config(hash: hash, iterations: iterations)),
                      child: Text('OK')),
                ],
              ),
            ));
  }

  Future<void> testPbkdf2Params(
    BuildContext context,
    HashFunction hash,
    int iterations,
  ) async {
    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/auth/test_pbkdf2_params';
    builder.queryParameters = {
      "function": hash.name,
      "iterations": iterations.toString(),
    };
    final request = Request('get', builder.build());

    final responseString =
        await sendRequest(context, 'Testing PBKDF2 Params', request);
    if (responseString == null || !context.mounted) return;
    final responseMap =
        (jsonDecode(responseString) as Map).cast<String, dynamic>();

    if (responseMap["success"]) {
      final time = Duration(microseconds: responseMap["time"]);
      await showAlertDialog(
        context,
        title:
            'Took ${time.inMilliseconds > 5 ? '${time.inMilliseconds}ms' : '${time.inMicroseconds}us'}',
        message: time.inMilliseconds < 300
            ? 'You should aim to take at least 300ms.'
            : time.inMilliseconds > 1000
                ? 'That\'s a long time. Consider lowering the number of iterations.'
                : 'Looks good!',
      );
    } else {
      await showAlertDialog(context,
          title: 'Could not test PBKDF2 params',
          message: "${responseMap["error"]}");
    }
  }
}

enum PasswordBackend {
  crypt('crypt', 'Crypt (Local DB)'),
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

  set passwordlessLoginEnabled(bool enabled) {
    state = state.copyWith(passwordlessLoginEnabled: enabled);
  }

  set passwordLoginEnabled(bool enabled) {
    state = state.copyWith(passwordLoginEnabled: enabled);
  }

  set passwordConfig(PasswordConfig config) {
    state = state.copyWith(passwordConfig: config);
  }

  void addOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(
        openIdConfigs:
            [...state.openIdConfigs, config].toList(growable: false));
  }

  void removeOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(
        openIdConfigs: state.openIdConfigs
            .whereNot((e) => e == config)
            .toList(growable: false));
  }
}

class AuthConfig {
  final bool passwordlessLoginEnabled;
  final bool passwordLoginEnabled;
  final PasswordConfig passwordConfig;
  final List<OpenIDConfig> openIdConfigs;

  const AuthConfig({
    required this.passwordlessLoginEnabled,
    required this.passwordLoginEnabled,
    required this.passwordConfig,
    required this.openIdConfigs,
  });

  const AuthConfig.defaults()
      : this(
          passwordlessLoginEnabled: false,
          passwordLoginEnabled: false,
          passwordConfig: const PasswordConfig(
            backend: PasswordBackend.crypt,
            cryptConfig: CryptConfig(
              kdf: CryptKDF.argon2,
              argon2Config: Argon2Config.defaults(),
              pbkdf2Config: Pbkdf2Config.defaults(),
            ),
            ldapConfig: LdapConfig.defaults(),
            resetEnabled: true,
          ),
          openIdConfigs: const [],
        );

  bool get valid =>
      passwordLoginEnabled ||
      passwordlessLoginEnabled ||
      openIdConfigs.isNotEmpty;

  AuthConfig copyWith({
    PasswordConfig? passwordConfig,
    bool? passwordLoginEnabled,
    bool? passwordlessLoginEnabled,
    List<OpenIDConfig>? openIdConfigs,
  }) {
    return AuthConfig(
      passwordlessLoginEnabled:
          passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
      passwordLoginEnabled: passwordLoginEnabled ?? this.passwordLoginEnabled,
      passwordConfig: passwordConfig ?? this.passwordConfig,
      openIdConfigs: openIdConfigs ?? this.openIdConfigs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'password': {
        if (passwordLoginEnabled)
          ...passwordConfig.toMap()
        else
          'backend': 'none',
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
        allowUnverifiedEmails:
            allowUnverifiedEmails ?? this.allowUnverifiedEmails,
        autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
      );
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
    return switch (backend) {
      PasswordBackend.crypt => {
          'backend': 'crypt',
          'crypt': cryptConfig.toMap(),
          'reset_enabled': resetEnabled,
        },
      PasswordBackend.ldap => {
          'backend': 'ldap',
          'ldap': ldapConfig.toMap(),
          'reset_enabled': false,
        },
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

  CryptConfig copyWith({
    CryptKDF? kdf,
    Argon2Config? argon2Config,
    Pbkdf2Config? pbkdf2Config,
  }) =>
      CryptConfig(
        kdf: kdf ?? this.kdf,
        argon2Config: argon2Config ?? this.argon2Config,
        pbkdf2Config: pbkdf2Config ?? this.pbkdf2Config,
      );

  Map<String, dynamic> toMap() => switch (kdf) {
        CryptKDF.argon2 => {
            'kdf': 'argon2',
            'argon2': argon2Config.toMap(),
          },
        CryptKDF.pbkdf2 => {
            'kdf': 'pbkdf2',
            'pbkdf2': pbkdf2Config.toMap(),
          },
      };

  @override
  String toString() => switch (kdf) {
        CryptKDF.argon2 => 'Argon2 ($argon2Config)',
        CryptKDF.pbkdf2 => 'PBKDF2 ($pbkdf2Config)',
      };
}

class Argon2Config {
  final int memory;
  final int parallelism;
  final int iterations;

  const Argon2Config(
      {required this.memory,
      required this.parallelism,
      required this.iterations});

  const Argon2Config.defaults()
      : this(memory: 16, parallelism: 2, iterations: 4);

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

  const Pbkdf2Config.defaults()
      : this(iterations: 600_000, hash: HashFunction.sha256);

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
