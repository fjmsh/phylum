import 'package:flutter/material.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/util/dialogs.dart';

import 'crypt_argon2.dart';
import 'crypt_pbkdf2.dart';

Future<CryptConfig?> configureKDF(
  BuildContext context,
  CryptConfig config,
  String instanceUrl,
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
    final argon2Config = await configureArgon2(
      context,
      config.argon2Config,
      instanceUrl,
    );
    if (argon2Config != null) {
      cryptConfig = config.copyWith(
        kdf: CryptKDF.argon2,
        argon2Config: argon2Config,
      );
    }
  } else if (kdf == CryptKDF.pbkdf2) {
    final pbkdf2Config = await configurePbkdf2(
      context,
      config.pbkdf2Config,
      instanceUrl,
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
