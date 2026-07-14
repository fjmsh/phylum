import 'dart:math';

import 'package:flutter/material.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/ui/settings/auth/auth_config_controller.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';

Future<CryptConfig?> configureKDF(
  BuildContext context,
  AuthConfigFormCubit bloc,
  CryptConfig config,
) async {
  final kdf = await showOptionsDialog(
    context,
    titleText: 'Select Password KDF',
    [CryptKDF.argon2, CryptKDF.pbkdf2],
    (item) => ListTile(title: Text(item.descriptor)),
  );
  if (kdf == null || !context.mounted) return null;

  CryptConfig? cryptConfig;
  if (kdf == CryptKDF.argon2) {
    final argon2Config = await showArgon2ConfigDialog(
      context,
      bloc,
      config.argon2Config,
    );
    if (argon2Config != null) {
      cryptConfig = config.copyWith(
        kdf: CryptKDF.argon2,
        argon2Config: argon2Config,
      );
    }
  } else if (kdf == CryptKDF.pbkdf2) {
    final pbkdf2Config = await showPbkdf2ConfigDialog(
      context,
      bloc,
      config.pbkdf2Config,
    );
    if (pbkdf2Config != null) {
      cryptConfig = config.copyWith(
        kdf: CryptKDF.pbkdf2,
        pbkdf2Config: pbkdf2Config,
      );
    }
  }
  return cryptConfig;
}

Future<Argon2Config?> showArgon2ConfigDialog(
  BuildContext context,
  AuthConfigFormCubit bloc,
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
                '$m - ${pow(2, m + 10).toInt().formatForDisplay(noDecimal: true)}',
              ),
              onTap: () async {
                final input = await showIntSliderDialog(
                  context,
                  title: 'Memory Factor (m)',
                  value: m,
                  min: 10,
                  max: 24,
                );
                if (input != null) {
                  setState(() => m = input);
                }
              },
            ),
            ListTile(
              title: Text('Parallelism'),
              subtitle: Text(p.toString()),
              onTap: () async {
                final input = await showIntSliderDialog(
                  context,
                  title: 'Parallelism (p)',
                  value: p,
                  min: 1,
                  max: 8,
                );
                if (input != null) {
                  setState(() => p = input);
                }
              },
            ),
            ListTile(
              title: Text('Iterations'),
              subtitle: Text(t.toString()),
              onTap: () async {
                final input = await showIntSliderDialog(
                  context,
                  title: 'Iterations (t)',
                  value: t,
                  min: 1,
                  max: 20,
                );
                if (input != null) {
                  setState(() => t = input);
                }
              },
            ),
            ElevatedButton(
              onPressed: () =>
                  testParams(context, () => bloc.testArgon2Params(m, t, p)),
              child: Text('Test Parameters'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(Argon2Config(memory: m, parallelism: p, iterations: t)),
            child: Text('OK'),
          ),
        ],
      ),
    ),
  );
}

Future<Pbkdf2Config?> showPbkdf2ConfigDialog(
  BuildContext context,
  AuthConfigFormCubit bloc,
  Pbkdf2Config config,
) async {
  var iterations = config.iterations;
  var hash = config.function;
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
                final input = await showOptionsDialog(context, [
                  HashFunction.sha1,
                  HashFunction.sha256,
                  HashFunction.sha512,
                ], (item) => ListTile(title: Text(item.descriptor)));
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
              onPressed: () => bloc.testPbkdf2Params(hash, iterations),
              child: Text('Test Parameters'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(Pbkdf2Config(function: hash, iterations: iterations)),
            child: Text('OK'),
          ),
        ],
      ),
    ),
  );
}

Future<void> testParams(
  BuildContext context,
  Future<KDFTestResult> Function() sendRequest,
) async {
  final nav = Navigator.of(context);

  showProgressDialog(
    context,
    barrierDismissible: false,
    message: 'Testing Parameters',
  );
  final result = await sendRequest();
  nav.pop();
  if (!context.mounted) return;

  switch (result) {
    case KDFTestSuccess():
      final time = result.duration;
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
    case KDFTestFailure():
      if (context.mounted) {
        showAlertDialog(
          context,
          barrierDismissible: false,
          title: result.title,
          message: result.details,
        );
      }
  }
}
