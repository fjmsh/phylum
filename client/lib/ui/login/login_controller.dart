import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/login/instance_config.dart';

class LoginController extends StateNotifier<LoginState> {
  LoginController(super.state);

  void reset() {
    state = LoginState(instanceUrl: state.instanceUrl);
  }

  set instanceUrl(Uri? value) {
    state = state.copyWith(instanceUrl: value, updateInstanceUrl: true);
  }

  set instanceInfo(InstanceInfo value) {
    state = state.copyWith(
        instanceUrl: value.url,
        updateInstanceUrl: true,
        instanceInfo: value,
        updateInstanceInfo: true);
  }

  set selectedMethod(LoginMethod? value) {
    state = state.copyWith(selectedMethod: value, updateSelectedMethod: true);
  }
}

class LoginState {
  final Uri? instanceUrl;
  final InstanceInfo? instanceInfo;
  final LoginMethod? selectedMethod;

  const LoginState({this.instanceUrl, this.instanceInfo, this.selectedMethod});

  LoginState copyWith({
    Uri? instanceUrl,
    bool updateInstanceUrl = false,
    InstanceInfo? instanceInfo,
    bool updateInstanceInfo = false,
    LoginMethod? selectedMethod,
    bool updateSelectedMethod = false,
  }) =>
      LoginState(
        instanceUrl: updateInstanceUrl ? instanceUrl : this.instanceUrl,
        instanceInfo: updateInstanceInfo ? instanceInfo : this.instanceInfo,
        selectedMethod:
            updateSelectedMethod ? selectedMethod : this.selectedMethod,
      );
}

enum LoginMethod {
  password,
  magicLink,
}
