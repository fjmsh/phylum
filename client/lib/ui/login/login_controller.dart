import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/login/instance_info.dart';
import 'package:phylum/ui/login/screens/email_login.dart';
import 'package:phylum/ui/login/screens/token_login.dart';
import 'package:phylum/ui/login/screens/reset_password.dart';

import 'package:phylum/util/base_uri/base_uri_stub.dart'
    if (dart.library.js_interop) 'package:phylum/util/base_uri/base_uri_web.dart';
import 'package:uri/uri.dart';

const bool instanceUrlFixed = kIsWeb && !kDebugMode;

class LoginController extends StateNotifier<LoginState> {
  LoginController(super.state);

  void reset([LoginState? newState]) {
    state = newState ?? LoginState._(instanceUrl: state.instanceUrl);
  }

  set instanceUrl(Uri? value) {
    state = state.copyWith(instanceUrl: value, updateInstanceUrl: true);
  }

  set instanceInfo(InstanceInfo value) {
    state = state.copyWith(
      instanceUrl: value.url,
      updateInstanceUrl: true,
      instanceInfo: value,
      updateInstanceInfo: true,
    );
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
    if (instanceUrlFixed || instanceUrl == null) {
      instanceUrl = webAppBaseUri;
    }

    // Strip trailing slash
    if (instanceUrl?.path.endsWith('/') == true) {
      final builder = UriBuilder.fromUri(instanceUrl!);
      builder.path = builder.path.substring(0, builder.path.length - 1);
      instanceUrl = builder.build();
    }

    return LoginState._(
      instanceUrl: instanceUrl,
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
  }) => LoginState._(
    instanceUrl: updateInstanceUrl ? instanceUrl : this.instanceUrl,
    instanceInfo: updateInstanceInfo ? instanceInfo : this.instanceInfo,
    selectedMethod: updateSelectedMethod ? selectedMethod : this.selectedMethod,
  );
}

sealed class LoginMethod {
  const LoginMethod();
  Widget build();
}

class EmailLoginMethod extends LoginMethod {
  const EmailLoginMethod();
  @override
  Widget build() => const EmailLoginScreen();
}

class TokenLoginMethod extends LoginMethod {
  final String? token;
  final String? error;

  const TokenLoginMethod({this.token, this.error});

  @override
  Widget build() => TokenLoginScreen(token: token, error: error);
}

class ResetPasswordMethod extends LoginMethod {
  final String? email;
  final String? token;

  const ResetPasswordMethod({required this.email, required this.token});

  @override
  Widget build() => ResetPasswordScreen(email: email, token: token);
}
