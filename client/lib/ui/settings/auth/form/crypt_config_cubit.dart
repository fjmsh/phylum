import 'package:bloc/bloc.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/config/config.dart';

class CryptConfigState {
  final Set<PrimitiveField> _fixed;
  final CryptKDF kdf;
  final bool resetEnabled;
  final int argon2Memory;
  final int argon2Iterations;
  final int argon2Parallelism;
  final HashFunction pbkdf2Hash;
  final int pbkdf2Iterations;

  CryptConfigState({
    required this._fixed,
    required this.kdf,
    required this.resetEnabled,
    required this.argon2Memory,
    required this.argon2Iterations,
    required this.argon2Parallelism,
    required this.pbkdf2Hash,
    required this.pbkdf2Iterations,
  });

  factory CryptConfigState.createFromRemoteConfig(
    RemoteConfig<AuthConfigFields> remote,
  ) {
    return CryptConfigState(
      fixed: remote.fixed,
      kdf: remote.getValue(AuthConfigFields.fieldPasswordCryptKdf),
      resetEnabled: remote.getValue(AuthConfigFields.fieldPasswordResetEnabled),
      argon2Memory: remote.getValue(
        AuthConfigFields.fieldPasswordCryptArgon2Memory,
      ),
      argon2Iterations: remote.getValue(
        AuthConfigFields.fieldPasswordCryptArgon2Iterations,
      ),
      argon2Parallelism: remote.getValue(
        AuthConfigFields.fieldPasswordCryptArgon2Parallelism,
      ),
      pbkdf2Hash: remote.getValue(
        AuthConfigFields.fieldPasswordCryptPbkdf2Hash,
      ),
      pbkdf2Iterations: remote.getValue(
        AuthConfigFields.fieldPasswordCryptPbkdf2Iterations,
      ),
    );
  }

  CryptConfigState copyWith({
    CryptKDF? kdf,
    bool? resetEnabled,
    int? argon2Memory,
    int? argon2Iterations,
    int? argon2Parallelism,
    HashFunction? pbkdf2Hash,
    int? pbkdf2Iterations,
  }) => CryptConfigState(
    fixed: _fixed,
    kdf: kdf ?? this.kdf,
    resetEnabled: resetEnabled ?? this.resetEnabled,
    argon2Memory: argon2Memory ?? this.argon2Memory,
    argon2Iterations: argon2Iterations ?? this.argon2Iterations,
    argon2Parallelism: argon2Parallelism ?? this.argon2Parallelism,
    pbkdf2Hash: pbkdf2Hash ?? this.pbkdf2Hash,
    pbkdf2Iterations: pbkdf2Iterations ?? this.pbkdf2Iterations,
  );

  bool isKdfFixed() => _fixed.contains(AuthConfigFields.fieldPasswordCryptKdf);
  bool isResetEnabledFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordResetEnabled);
  bool isArgon2MemoryFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordCryptArgon2Memory);
  bool isArgon2IterationsFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordCryptArgon2Iterations);
  bool isArgon2ParallelismFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordCryptArgon2Parallelism);
  bool isPbkdf2HashFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordCryptPbkdf2Hash);
  bool isPbkdf2IterationsFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordCryptPbkdf2Iterations);

  @override
  bool operator ==(covariant CryptConfigState other) {
    if (identical(this, other)) return true;
    return kdf == other.kdf &&
        resetEnabled == other.resetEnabled &&
        argon2Memory == other.argon2Memory &&
        argon2Iterations == other.argon2Iterations &&
        argon2Parallelism == other.argon2Parallelism &&
        pbkdf2Hash == other.pbkdf2Hash &&
        pbkdf2Iterations == other.pbkdf2Iterations;
  }

  @override
  int get hashCode =>
      kdf.hashCode ^
      resetEnabled.hashCode ^
      argon2Memory.hashCode ^
      argon2Iterations.hashCode ^
      argon2Parallelism.hashCode ^
      pbkdf2Hash.hashCode ^
      pbkdf2Iterations.hashCode;
}

class CryptConfigCubit extends Cubit<CryptConfigState> {
  CryptConfigCubit({required RemoteConfig<AuthConfigFields> remote})
    : super(CryptConfigState.createFromRemoteConfig(remote));

  set kdf(CryptKDF val) {
    emit(state.copyWith(kdf: val));
  }

  set resetEnabled(bool val) {
    emit(state.copyWith(resetEnabled: val));
  }

  set argon2Memory(int val) {
    emit(state.copyWith(argon2Memory: val));
  }

  set argon2Iterations(int val) {
    emit(state.copyWith(argon2Iterations: val));
  }

  set argon2Parallelism(int val) {
    emit(state.copyWith(argon2Parallelism: val));
  }

  set pbkdf2Hash(HashFunction val) {
    emit(state.copyWith(pbkdf2Hash: val));
  }

  set pbkdf2Iterations(int val) {
    emit(state.copyWith(pbkdf2Iterations: val));
  }

  LocalConfig<AuthConfigFields>? validate() {
    return LocalConfig<AuthConfigFields>()
      ..set<CryptKDF>(AuthConfigFields.fieldPasswordCryptKdf, state.kdf)
      ..set<bool>(
        AuthConfigFields.fieldPasswordResetEnabled,
        state.resetEnabled,
      )
      ..set<int>(
        AuthConfigFields.fieldPasswordCryptArgon2Memory,
        state.argon2Memory,
      )
      ..set<int>(
        AuthConfigFields.fieldPasswordCryptArgon2Iterations,
        state.argon2Iterations,
      )
      ..set<int>(
        AuthConfigFields.fieldPasswordCryptArgon2Parallelism,
        state.argon2Parallelism,
      )
      ..set<HashFunction>(
        AuthConfigFields.fieldPasswordCryptPbkdf2Hash,
        state.pbkdf2Hash,
      )
      ..set<int>(
        AuthConfigFields.fieldPasswordCryptPbkdf2Iterations,
        state.pbkdf2Iterations,
      );
  }
}
