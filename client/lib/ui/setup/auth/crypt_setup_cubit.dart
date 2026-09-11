import 'package:phylum/ui/config/auth/crypt/crypt_config.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config_cubit.dart';

class CryptSetupCubit extends CryptConfigCubit {
  CryptSetupCubit({required super.remote});

  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) => throw UnimplementedError('Not implemented');
}
