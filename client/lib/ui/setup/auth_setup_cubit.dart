import 'package:phylum/ui/config/auth/auth_config.dart';
import 'package:phylum/ui/config/auth/form/auth_config_form_cubit.dart';

class AuthSetupCubit extends AuthConfigCubit {
  AuthSetupCubit({required super.remote});

  @override
  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) async {
    return KDFTestFailure(title: 'Unimplemented');
  }
}
