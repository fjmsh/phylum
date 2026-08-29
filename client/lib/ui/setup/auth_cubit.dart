import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/auth/form/auth_config_form_cubit.dart';

class AuthConfigSetupCubit extends AuthConfigFormCubit {
  AuthConfigSetupCubit({required super.remote});

  @override
  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) async {
    return KDFTestFailure(title: 'Unimplemented');
  }
}
