import 'package:phylum/ui/config/config.dart';

class CryptConfigFields extends ConfigFields {
  static final fieldKdf = PrimitiveField(
    CryptKDF.argon2,
    toPrimitive: (val) => val.name,
    fromPrimitive: (val) => CryptKDF.fromString(val),
  );
  static final fieldArgon2Memory = PrimitiveField(16);
  static final fieldArgon2Iterations = PrimitiveField(4);
  static final fieldArgon2Parallelism = PrimitiveField(2);
  static final fieldPbkdf2Hash = PrimitiveField(
    HashFunction.sha256,
    toPrimitive: (val) => val.name,
    fromPrimitive: (val) => HashFunction.fromString(val),
  );
  static final fieldPbkdf2Iterations = PrimitiveField(600_000);

  static CryptConfigFields instance = CryptConfigFields._();

  CryptConfigFields._();

  @override
  AnonymousObjectField get root => AnonymousObjectField({
    "kdf": fieldKdf,
    "argon2": AnonymousObjectField({
      "memory": fieldArgon2Memory,
      "iterations": fieldArgon2Iterations,
      "parallelism": fieldArgon2Parallelism,
    }),
    "pbkdf2": AnonymousObjectField({
      "function": fieldPbkdf2Hash,
      "iterations": fieldPbkdf2Iterations,
    }),
  });
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

enum HashFunction {
  sha1('sha-1', 'SHA-1'),
  sha256('sha-256', 'SHA-256'),
  sha512('sha-512', 'SHA-512');

  final String name;
  final String descriptor;

  const HashFunction(this.name, this.descriptor);

  static HashFunction fromString(String s) {
    for (final h in HashFunction.values) {
      if (h.name == s) {
        return h;
      }
    }
    return .sha256;
  }
}
