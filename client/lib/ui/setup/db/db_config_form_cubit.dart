import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/ui/setup/config_check_result.dart';
import 'package:phylum/ui/setup/db/db_config.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class DbConfigFormState {
  final Set<PrimitiveField> _fixed;
  final String host;
  final String port;
  final String dbName;
  final String user;
  final String password;
  final String? hostError;
  final String? portError;
  final String? dbNameError;
  final String? userError;

  DbConfigFormState({
    required this._fixed,
    required this.host,
    required this.port,
    required this.dbName,
    required this.user,
    required this.password,
    this.hostError,
    this.portError,
    this.dbNameError,
    this.userError,
  });

  factory DbConfigFormState.createFromRemoteConfig(
    RemoteConfig<DbConfigFields> config,
  ) {
    return DbConfigFormState(
      fixed: config.fixed,
      host: config.getValueOrDefault(DbConfigFields.fieldHost),
      port: config.getValueOrDefault(DbConfigFields.fieldPort).toString(),
      dbName: config.getValueOrDefault(DbConfigFields.fieldDbName),
      user: config.getValueOrDefault(DbConfigFields.fieldUser),
      password: config.getValueOrDefault(DbConfigFields.fieldPassword),
    );
  }

  DbConfigFormState copyWith({
    bool? enabled,
    String? host,
    String? port,
    String? dbName,
    String? user,
    String? password,
  }) {
    return DbConfigFormState(
      fixed: _fixed,
      host: host ?? this.host,
      port: port ?? this.port,
      dbName: dbName ?? this.dbName,
      user: user ?? this.user,
      password: password ?? this.password,
    );
  }

  DbConfigFormState withErrors({
    String? hostError,
    String? portError,
    String? dbNameError,
    String? userError,
  }) {
    return DbConfigFormState(
      fixed: _fixed,
      host: host,
      port: port,
      user: user,
      password: password,
      dbName: dbName,
      hostError: hostError ?? this.hostError,
      portError: portError ?? this.portError,
      dbNameError: dbNameError ?? this.dbNameError,
      userError: userError ?? this.userError,
    );
  }

  bool hasHostOverride() => _fixed.contains(DbConfigFields.fieldHost);
  bool hasPortOverride() => _fixed.contains(DbConfigFields.fieldPort);
  bool hasDbNameOverride() => _fixed.contains(DbConfigFields.fieldDbName);
  bool hasUserOverride() => _fixed.contains(DbConfigFields.fieldUser);
  bool hasPasswordOverride() => _fixed.contains(DbConfigFields.fieldPassword);

  @override
  String toString() {
    return 'DbConfigFormState('
        'host: $host, '
        'hostError: $hostError, '
        'port: $port, '
        'portError: $portError, '
        'dbName: $dbName, '
        'dbNameError: $dbNameError, '
        'user: $user, '
        'userError: $userError, '
        'password: $password, ';
  }

  @override
  bool operator ==(covariant DbConfigFormState other) {
    if (identical(this, other)) return true;

    return (const SetEquality()).equals(other._fixed, _fixed) &&
        other.host == host &&
        other.hostError == hostError &&
        other.port == port &&
        other.portError == portError &&
        other.dbName == dbName &&
        other.dbNameError == dbNameError &&
        other.user == user &&
        other.userError == userError &&
        other.password == password;
  }

  @override
  int get hashCode {
    return host.hashCode ^
        hostError.hashCode ^
        port.hashCode ^
        portError.hashCode ^
        dbName.hashCode ^
        dbNameError.hashCode ^
        user.hashCode ^
        userError.hashCode ^
        password.hashCode;
  }
}

class DbConfigFormCubit extends Cubit<DbConfigFormState> {
  final String _instanceUrl;
  final RemoteConfig<DbConfigFields> _remoteConfig;

  DbConfigFormCubit({required this._remoteConfig, required this._instanceUrl})
    : super(DbConfigFormState.createFromRemoteConfig(_remoteConfig));

  set host(String val) {
    emit(state.copyWith(host: val));
  }

  set port(String val) {
    emit(state.copyWith(port: val));
  }

  set dbName(String val) {
    emit(state.copyWith(dbName: val));
  }

  set user(String val) {
    emit(state.copyWith(user: val));
  }

  set password(String val) {
    emit(state.copyWith(password: val));
  }

  Map<String, dynamic>? validateConfig() {
    var newState = state;
    final config = LocalConfig<DbConfigFields>();

    if (!state.hasHostOverride()) {
      newState = newState.withErrors(
        hostError: state.host == '' ? 'Required' : null,
      );
      config.setValue<String>(DbConfigFields.fieldHost, state.host);
    }

    if (!state.hasPortOverride()) {
      final port = int.tryParse(state.port) ?? 0;
      newState = newState.withErrors(
        portError: state.port.isEmpty
            ? 'Required'
            : port == 0
            ? 'Invalid Port'
            : null,
      );
      config.setValue<int>(DbConfigFields.fieldPort, port);
    }

    if (!state.hasDbNameOverride()) {
      newState = newState.withErrors(
        dbNameError: state.dbName == '' ? 'Required' : null,
      );
      config.setValue<String>(DbConfigFields.fieldDbName, state.dbName);
    }

    if (!state.hasUserOverride()) {
      newState = newState.withErrors(
        userError: state.user == '' ? 'Required' : null,
      );
      config.setValue<String>(DbConfigFields.fieldUser, state.user);
    }
    config.setValue<String>(DbConfigFields.fieldPassword, state.password);

    if (state == newState) {
      return config.toMap(_remoteConfig);
    } else {
      emit(newState);
      return null;
    }
  }

  Future<ConfigCheckResult> checkConfig() async {
    final config = validateConfig();
    if (config == null) return const ConfigInvalid();

    final builder = UriBuilder.fromUri(Uri.parse(_instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/db/validate';
    final request = Request('post', builder.build());
    request.body = jsonEncode(config);

    final result = await sendRequest(request);
    if (result is SuccessResponse) {
      final responseMap = (jsonDecode(result.responseString) as Map)
          .cast<String, dynamic>();

      final error = (responseMap['error'] as Map?)?.cast<String, dynamic>();
      final warning = (responseMap['warning'] as Map?)?.cast<String, dynamic>();
      if (error != null) {
        return ConfigCheckError(
          config: config,
          title: error['msg'],
          message: error['details'],
        );
      } else if (warning != null) {
        return ConfigCheckWarning(config: config, code: warning['code']);
      }
      return ConfigCheckSuccess(config: config);
    } else {
      return ConfigCheckError(config: config, message: result.toString());
    }
  }
}
