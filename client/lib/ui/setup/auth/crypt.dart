import 'package:flutter/material.dart';
import 'package:phylum/ui/setup/auth/crypt_argon2.dart';
import 'package:phylum/ui/setup/auth/crypt_pbkdf2.dart';
import 'package:phylum/util/dialogs.dart';

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
}
