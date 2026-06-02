import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/ui/login/login_magic_link.dart';
import 'package:phylum/ui/login/login_password.dart';
import 'package:phylum/ui/login/login_token.dart';
import 'package:phylum/ui/login/reset_password_page.dart';

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
  final String? email;
  final String? token;

  const LoginState({
    this.instanceUrl,
    this.instanceInfo,
    this.selectedMethod,
    this.email,
    this.token,
  });

  LoginState copyWith({
    Uri? instanceUrl,
    bool updateInstanceUrl = false,
    InstanceInfo? instanceInfo,
    bool updateInstanceInfo = false,
    LoginMethod? selectedMethod,
    bool updateSelectedMethod = false,
    String? email,
    bool updateEmail = false,
    String? token,
    bool updateToken = false,
  }) =>
      LoginState(
        instanceUrl: updateInstanceUrl ? instanceUrl : this.instanceUrl,
        instanceInfo: updateInstanceInfo ? instanceInfo : this.instanceInfo,
        selectedMethod:
            updateSelectedMethod ? selectedMethod : this.selectedMethod,
        email: updateEmail ? email : this.email,
        token: updateToken ? token : this.token,
      );
}

sealed class LoginMethod {
  const LoginMethod();
  Widget build();
}

class PasswordLoginMethod extends LoginMethod {
  const PasswordLoginMethod();
  @override
  Widget build() => const PasswordLogin();
}

class MagicLinkLoginMethod extends LoginMethod {
  const MagicLinkLoginMethod();
  @override
  Widget build() => const MagicLinkLogin();
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
  Widget build() => ResetPasswordPage(email: email, token: token);
}
