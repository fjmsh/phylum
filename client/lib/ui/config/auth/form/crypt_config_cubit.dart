import 'package:bloc/bloc.dart';
import 'package:phylum/ui/config/auth/auth_config.dart';
import 'package:phylum/ui/config/config.dart';

class CryptConfigState {
  final Set<PrimitiveField> _fixed;
  final bool shouldAllowKdfSelection;
  final CryptKDF kdf;
  final bool resetEnabled;
  final String argon2Memory;
  final String argon2Iterations;
  final String argon2Parallelism;
  final String? argon2MemoryError;
  final String? argon2IterationsError;
  final String? argon2ParallelismError;
  final HashFunction pbkdf2Hash;
  final String pbkdf2Iterations;
  final String? pbkdf2IterationsError;

  CryptConfigState({
    required this._fixed,
    required this.shouldAllowKdfSelection,
    required this.kdf,
    required this.resetEnabled,
    required this.argon2Memory,
    required this.argon2Iterations,
    required this.argon2Parallelism,
    required this.argon2MemoryError,
    required this.argon2IterationsError,
    required this.argon2ParallelismError,
    required this.pbkdf2Hash,
    required this.pbkdf2Iterations,
    required this.pbkdf2IterationsError,
  });

  factory CryptConfigState.createFromRemoteConfig(
    RemoteConfig<AuthConfigFields> remote,
  ) {
    final kdf = remote.getValueOrDefault(
      AuthConfigFields.fieldPasswordCryptKdf,
    );
    return CryptConfigState(
      fixed: remote.fixed,
      shouldAllowKdfSelection: kdf != CryptKDF.argon2,
      kdf: kdf,
      resetEnabled: remote.getValueOrDefault(
        AuthConfigFields.fieldPasswordResetEnabled,
      ),
      argon2Memory: remote
          .getValueOrDefault(AuthConfigFields.fieldPasswordCryptArgon2Memory)
          .toString(),
      argon2Iterations: remote
          .getValueOrDefault(
            AuthConfigFields.fieldPasswordCryptArgon2Iterations,
          )
          .toString(),
      argon2Parallelism: remote
          .getValueOrDefault(
            AuthConfigFields.fieldPasswordCryptArgon2Parallelism,
          )
          .toString(),
      argon2MemoryError: null,
      argon2IterationsError: null,
      argon2ParallelismError: null,
      pbkdf2Hash: remote.getValueOrDefault(
        AuthConfigFields.fieldPasswordCryptPbkdf2Hash,
      ),
      pbkdf2Iterations: remote
          .getValueOrDefault(
            AuthConfigFields.fieldPasswordCryptPbkdf2Iterations,
          )
          .toString(),
      pbkdf2IterationsError: null,
    );
  }

  CryptConfigState copyWith({
    CryptKDF? kdf,
    bool? resetEnabled,
    String? argon2Memory,
    String? argon2Iterations,
    String? argon2Parallelism,
    HashFunction? pbkdf2Hash,
    String? pbkdf2Iterations,
  }) => CryptConfigState(
    fixed: _fixed,
    shouldAllowKdfSelection: shouldAllowKdfSelection,
    kdf: kdf ?? this.kdf,
    resetEnabled: resetEnabled ?? this.resetEnabled,
    argon2Memory: argon2Memory ?? this.argon2Memory,
    argon2Iterations: argon2Iterations ?? this.argon2Iterations,
    argon2Parallelism: argon2Parallelism ?? this.argon2Parallelism,
    argon2MemoryError: null,
    argon2IterationsError: null,
    argon2ParallelismError: null,
    pbkdf2Hash: pbkdf2Hash ?? this.pbkdf2Hash,
    pbkdf2Iterations: pbkdf2Iterations ?? this.pbkdf2Iterations,
    pbkdf2IterationsError: null,
  );

  CryptConfigState copyWithErrors({
    String? argon2MemoryError,
    String? argon2IterationsError,
    String? argon2ParallelismError,
    String? pbkdf2IterationsError,
  }) => CryptConfigState(
    fixed: _fixed,
    shouldAllowKdfSelection: shouldAllowKdfSelection,
    kdf: kdf,
    resetEnabled: resetEnabled,
    argon2Memory: argon2Memory,
    argon2Iterations: argon2Iterations,
    argon2Parallelism: argon2Parallelism,
    argon2MemoryError: argon2MemoryError,
    argon2IterationsError: argon2IterationsError,
    argon2ParallelismError: argon2ParallelismError,
    pbkdf2Hash: pbkdf2Hash,
    pbkdf2Iterations: pbkdf2Iterations,
    pbkdf2IterationsError: pbkdf2IterationsError,
  );

  bool get hasErrors =>
      argon2MemoryError != null ||
      argon2IterationsError != null ||
      argon2ParallelismError != null ||
      pbkdf2IterationsError != null;

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
        argon2MemoryError == other.argon2MemoryError &&
        argon2IterationsError == other.argon2IterationsError &&
        argon2ParallelismError == other.argon2ParallelismError &&
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
      argon2MemoryError.hashCode ^
      argon2IterationsError.hashCode ^
      argon2ParallelismError.hashCode ^
      pbkdf2Hash.hashCode ^
      pbkdf2Iterations.hashCode;
}

class CryptConfigCubit extends Cubit<CryptConfigState> {
  CryptConfigCubit({required RemoteConfig<AuthConfigFields> remote})
    : super(CryptConfigState.createFromRemoteConfig(remote));

  void reset(RemoteConfig<AuthConfigFields> remote) {
    emit(CryptConfigState.createFromRemoteConfig(remote));
  }

  set kdf(CryptKDF val) {
    emit(state.copyWith(kdf: val));
  }

  set resetEnabled(bool val) {
    emit(state.copyWith(resetEnabled: val));
  }

  set argon2Memory(String val) {
    emit(state.copyWith(argon2Memory: val));
  }

  set argon2Iterations(String val) {
    emit(state.copyWith(argon2Iterations: val));
  }

  set argon2Parallelism(String val) {
    emit(state.copyWith(argon2Parallelism: val));
  }

  set pbkdf2Hash(HashFunction val) {
    emit(state.copyWith(pbkdf2Hash: val));
  }

  set pbkdf2Iterations(String val) {
    emit(state.copyWith(pbkdf2Iterations: val));
  }

  LocalConfig<AuthConfigFields>? validate() {
    final config = LocalConfig<AuthConfigFields>();
    config.setValue<CryptKDF>(
      AuthConfigFields.fieldPasswordCryptKdf,
      state.kdf,
    );
    config.setValue<bool>(
      AuthConfigFields.fieldPasswordResetEnabled,
      state.resetEnabled,
    );

    final kdfConfig = switch (state.kdf) {
      CryptKDF.argon2 => _validateArgon2(),
      CryptKDF.pbkdf2 => _validatePbkdf2(),
    };
    if (kdfConfig == null) {
      return null;
    }

    config.values.addAll(kdfConfig.values);

    return config;
  }

  LocalConfig<AuthConfigFields>? _validateArgon2() {
    final argon2Memory = int.tryParse(state.argon2Memory);
    final argon2Iterations = int.tryParse(state.argon2Iterations);
    final argon2Parallelism = int.tryParse(state.argon2Parallelism);

    final newState = state.copyWithErrors(
      argon2MemoryError: state.argon2Memory.isEmpty
          ? 'Required'
          : argon2Memory == null
          ? 'Must be a number'
          : argon2Memory < 8 || argon2Memory > 32
          ? 'Out of Bounds'
          : null,
      argon2IterationsError: state.argon2Iterations.isEmpty
          ? 'Required'
          : argon2Iterations == null
          ? 'Must be a number'
          : argon2Iterations < 1
          ? 'Out of Bounds'
          : null,
      argon2ParallelismError: state.argon2Parallelism.isEmpty
          ? 'Required'
          : argon2Parallelism == null
          ? 'Must be a number'
          : argon2Parallelism < 1
          ? 'Out of Bounds'
          : null,
    );
    if (newState != state) {
      emit(newState);
      return null;
    }

    return LocalConfig()
      ..setValue<int>(
        AuthConfigFields.fieldPasswordCryptArgon2Memory,
        argon2Memory!,
      )
      ..setValue<int>(
        AuthConfigFields.fieldPasswordCryptArgon2Iterations,
        argon2Iterations!,
      )
      ..setValue<int>(
        AuthConfigFields.fieldPasswordCryptArgon2Parallelism,
        argon2Parallelism!,
      );
  }

  LocalConfig<AuthConfigFields>? _validatePbkdf2() {
    final pbkdf2Iterations = int.tryParse(state.pbkdf2Iterations);

    final newState = state.copyWithErrors(
      pbkdf2IterationsError: state.argon2Iterations.isEmpty
          ? 'Required'
          : pbkdf2Iterations == null
          ? 'Must be a number'
          : pbkdf2Iterations < 1
          ? 'Out of Bounds'
          : null,
    );
    if (newState.hasErrors) {
      emit(newState);
      return null;
    }
    return LocalConfig()
      ..setValue<HashFunction>(
        AuthConfigFields.fieldPasswordCryptPbkdf2Hash,
        state.pbkdf2Hash,
      )
      ..setValue<int>(
        AuthConfigFields.fieldPasswordCryptPbkdf2Iterations,
        pbkdf2Iterations!,
      );
  }
}
