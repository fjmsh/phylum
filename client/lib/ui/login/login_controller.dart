import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/login_email.dart';
import 'package:phylum/ui/login/login_token.dart';
import 'package:phylum/ui/login/login_reset_password.dart';

import 'package:phylum/util/base_uri/base_uri_stub.dart'
    if (dart.library.js_interop) 'package:phylum/util/base_uri/base_uri_web.dart';

const bool instanceUrlFixed = kIsWeb && !kDebugMode;

class LoginController extends StateNotifier<LoginState> {
  LoginController(super.state);

  void reset() {
    state = LoginState._(instanceUrl: state.instanceUrl);
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

  const LoginState._({
    this.instanceUrl,
    this.instanceInfo,
    this.selectedMethod,
  });

  factory LoginState.create({Uri? instanceUrl, LoginMethod? selectedMethod}) {
    return LoginState._(
      instanceUrl:
          instanceUrlFixed ? webAppBaseUri : instanceUrl ?? webAppBaseUri,
      selectedMethod: selectedMethod,
    );
  }

  LoginState copyWith({
    Uri? instanceUrl,
    bool updateInstanceUrl = false,
    InstanceInfo? instanceInfo,
    bool updateInstanceInfo = false,
    LoginMethod? selectedMethod,
    bool updateSelectedMethod = false,
  }) =>
      LoginState._(
        instanceUrl: updateInstanceUrl ? instanceUrl : this.instanceUrl,
        instanceInfo: updateInstanceInfo ? instanceInfo : this.instanceInfo,
        selectedMethod:
            updateSelectedMethod ? selectedMethod : this.selectedMethod,
      );
}

sealed class LoginMethod {
  const LoginMethod();
  Widget build();
}

class EmailLoginMethod extends LoginMethod {
  const EmailLoginMethod();
  @override
  Widget build() => const EmailLogin();
}

class TokenLoginMethod extends LoginMethod {
  final String? token;

  const TokenLoginMethod(this.token);

  @override
  Widget build() => TokenLogin(token: token);
}

class ResetPasswordMethod extends LoginMethod {
  final String? email;
  final String? token;

  const ResetPasswordMethod({required this.email, required this.token});

  @override
  Widget build() => ResetPasswordLogin(email: email, token: token);
}
