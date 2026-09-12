import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:phylum/ui/config/config.dart';

import 'crypt_config.dart';

class CryptConfigState {
  final Set<PrimitiveField> _fixed;
  final bool shouldAllowKdfSelection;
  final CryptKDF kdf;
  final String argon2Memory;
  final String argon2Iterations;
  final String argon2Parallelism;
  final String? argon2MemoryError;
  final String? argon2IterationsError;
  final String? argon2ParallelismError;
  final HashFunction pbkdf2Hash;
  final String pbkdf2Iterations;
  final String? pbkdf2IterationsError;
  final bool checkingParams;

  CryptConfigState({
    required this._fixed,
    required this.shouldAllowKdfSelection,
    required this.kdf,
    required this.argon2Memory,
    required this.argon2Iterations,
    required this.argon2Parallelism,
    required this.argon2MemoryError,
    required this.argon2IterationsError,
    required this.argon2ParallelismError,
    required this.pbkdf2Hash,
    required this.pbkdf2Iterations,
    required this.pbkdf2IterationsError,
    required this.checkingParams,
  });

  factory CryptConfigState.createFromRemoteConfig(
    RemoteConfig<CryptConfigFields> remote,
  ) {
    final kdf = remote.getValueOrDefault(CryptConfigFields.fieldKdf);
    return CryptConfigState(
      fixed: remote.fixed,
      shouldAllowKdfSelection: kdf != CryptKDF.argon2,
      kdf: kdf,
      argon2Memory: remote
          .getValueOrDefault(CryptConfigFields.fieldArgon2Memory)
          .toString(),
      argon2Iterations: remote
          .getValueOrDefault(CryptConfigFields.fieldArgon2Iterations)
          .toString(),
      argon2Parallelism: remote
          .getValueOrDefault(CryptConfigFields.fieldArgon2Parallelism)
          .toString(),
      argon2MemoryError: null,
      argon2IterationsError: null,
      argon2ParallelismError: null,
      pbkdf2Hash: remote.getValueOrDefault(CryptConfigFields.fieldPbkdf2Hash),
      pbkdf2Iterations: remote
          .getValueOrDefault(CryptConfigFields.fieldPbkdf2Iterations)
          .toString(),
      pbkdf2IterationsError: null,
      checkingParams: false,
    );
  }

  CryptConfigState copyWith({
    CryptKDF? kdf,
    String? argon2Memory,
    String? argon2Iterations,
    String? argon2Parallelism,
    HashFunction? pbkdf2Hash,
    String? pbkdf2Iterations,
    bool? checkingParams,
  }) => CryptConfigState(
    fixed: _fixed,
    shouldAllowKdfSelection: shouldAllowKdfSelection,
    kdf: kdf ?? this.kdf,
    argon2Memory: argon2Memory ?? this.argon2Memory,
    argon2Iterations: argon2Iterations ?? this.argon2Iterations,
    argon2Parallelism: argon2Parallelism ?? this.argon2Parallelism,
    argon2MemoryError: null,
    argon2IterationsError: null,
    argon2ParallelismError: null,
    pbkdf2Hash: pbkdf2Hash ?? this.pbkdf2Hash,
    pbkdf2Iterations: pbkdf2Iterations ?? this.pbkdf2Iterations,
    pbkdf2IterationsError: null,
    checkingParams: checkingParams ?? this.checkingParams,
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
    argon2Memory: argon2Memory,
    argon2Iterations: argon2Iterations,
    argon2Parallelism: argon2Parallelism,
    argon2MemoryError: argon2MemoryError,
    argon2IterationsError: argon2IterationsError,
    argon2ParallelismError: argon2ParallelismError,
    pbkdf2Hash: pbkdf2Hash,
    pbkdf2Iterations: pbkdf2Iterations,
    pbkdf2IterationsError: pbkdf2IterationsError,
    checkingParams: checkingParams,
  );

  bool get hasErrors =>
      argon2MemoryError != null ||
      argon2IterationsError != null ||
      argon2ParallelismError != null ||
      pbkdf2IterationsError != null;

  bool isKdfFixed() => _fixed.contains(CryptConfigFields.fieldKdf);
  bool isArgon2MemoryFixed() =>
      _fixed.contains(CryptConfigFields.fieldArgon2Memory);
  bool isArgon2IterationsFixed() =>
      _fixed.contains(CryptConfigFields.fieldArgon2Iterations);
  bool isArgon2ParallelismFixed() =>
      _fixed.contains(CryptConfigFields.fieldArgon2Parallelism);
  bool isPbkdf2HashFixed() =>
      _fixed.contains(CryptConfigFields.fieldPbkdf2Hash);
  bool isPbkdf2IterationsFixed() =>
      _fixed.contains(CryptConfigFields.fieldPbkdf2Iterations);

  @override
  bool operator ==(covariant CryptConfigState other) {
    if (identical(this, other)) return true;
    return kdf == other.kdf &&
        argon2Memory == other.argon2Memory &&
        argon2Iterations == other.argon2Iterations &&
        argon2Parallelism == other.argon2Parallelism &&
        argon2MemoryError == other.argon2MemoryError &&
        argon2IterationsError == other.argon2IterationsError &&
        argon2ParallelismError == other.argon2ParallelismError &&
        pbkdf2Hash == other.pbkdf2Hash &&
        pbkdf2Iterations == other.pbkdf2Iterations &&
        pbkdf2IterationsError == other.pbkdf2IterationsError &&
        checkingParams == other.checkingParams;
  }

  @override
  int get hashCode =>
      kdf.hashCode ^
      argon2Memory.hashCode ^
      argon2Iterations.hashCode ^
      argon2Parallelism.hashCode ^
      argon2MemoryError.hashCode ^
      argon2IterationsError.hashCode ^
      argon2ParallelismError.hashCode ^
      pbkdf2Hash.hashCode ^
      pbkdf2Iterations.hashCode ^
      pbkdf2IterationsError.hashCode ^
      checkingParams.hashCode;
}

abstract class CryptConfigCubit extends Cubit<CryptConfigState> {
  final RemoteConfig<CryptConfigFields> _remote;

  CryptConfigCubit({required this._remote})
    : super(CryptConfigState.createFromRemoteConfig(_remote));

  void reset() {
    emit(
      CryptConfigState.createFromRemoteConfig(
        _remote,
      ).copyWith(checkingParams: state.checkingParams),
    );
  }

  set kdf(CryptKDF val) {
    emit(state.copyWith(kdf: val));
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

  LocalConfig<CryptConfigFields>? validate() {
    final config = LocalConfig<CryptConfigFields>();
    config.setValue<CryptKDF>(CryptConfigFields.fieldKdf, state.kdf);

    final kdfConfig = switch (state.kdf) {
      .argon2 => _validateArgon2(),
      .pbkdf2 => _validatePbkdf2(),
    };
    if (kdfConfig == null) {
      return null;
    }

    config.values.addAll(kdfConfig.values);

    return config;
  }

  LocalConfig<CryptConfigFields>? _validateArgon2() {
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
      ..setValue<int>(CryptConfigFields.fieldArgon2Memory, argon2Memory!)
      ..setValue<int>(
        CryptConfigFields.fieldArgon2Iterations,
        argon2Iterations!,
      )
      ..setValue<int>(
        CryptConfigFields.fieldArgon2Parallelism,
        argon2Parallelism!,
      );
  }

  LocalConfig<CryptConfigFields>? _validatePbkdf2() {
    final pbkdf2Iterations = int.tryParse(state.pbkdf2Iterations);

    final newState = state.copyWithErrors(
      pbkdf2IterationsError: state.pbkdf2Iterations.isEmpty
          ? 'Required'
          : pbkdf2Iterations == null
          ? 'Must be a number'
          : pbkdf2Iterations < 1
          ? 'Out of Bounds'
          : null,
    );
    if (newState.hasErrors) {
      emit(newState);
      print(state.pbkdf2IterationsError);
      return null;
    }
    return LocalConfig()
      ..setValue<HashFunction>(
        CryptConfigFields.fieldPbkdf2Hash,
        state.pbkdf2Hash,
      )
      ..setValue<int>(
        CryptConfigFields.fieldPbkdf2Iterations,
        pbkdf2Iterations!,
      );
  }

  Future<KDFTestResult> testKdfParams() async {
    if (state.checkingParams) {
      return KDFTestFailure(title: 'Already checking params');
    }
    emit(state.copyWith(checkingParams: true));
    try {
      switch (state.kdf) {
        case .argon2:
          final memory = int.tryParse(state.argon2Memory);
          final iterations = int.tryParse(state.argon2Iterations);
          final parallelism = int.tryParse(state.argon2Parallelism);
          if (memory == null || iterations == null || parallelism == null) {
            return KDFTestFailure(title: 'Invalid Parameters');
          }
          return await testParams(
            kdf: .argon2,
            params: {
              "memory": memory,
              "iterations": iterations,
              "parallelism": parallelism,
            },
          );
        case .pbkdf2:
          final iterations = int.tryParse(state.pbkdf2Iterations);
          if (iterations == null) {
            return KDFTestFailure(title: 'Invalid Parameters');
          }
          return await testParams(
            kdf: .pbkdf2,
            params: {
              "function": state.pbkdf2Hash.name,
              "iterations": iterations,
            },
          );
      }
    } finally {
      emit(state.copyWith(checkingParams: false));
    }
  }

  @protected
  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  });
}

sealed class KDFTestResult {
  const KDFTestResult();
}

class KDFTestFailure extends KDFTestResult {
  final String title;

  final String? details;

  const KDFTestFailure({required this.title, this.details});
}

class KDFTestSuccess extends KDFTestResult {
  final Duration duration;

  const KDFTestSuccess({required this.duration});
}
