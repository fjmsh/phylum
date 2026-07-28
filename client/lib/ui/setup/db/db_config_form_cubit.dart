import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/settings/config/local_config.dart';
import 'package:phylum/ui/settings/config/remote_config.dart';
import 'package:phylum/ui/setup/db/db_config.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class DbConfigFormState {
  final Set<PrimitiveField> _overrides;
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
    required this._overrides,
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
    final overrides = Set.of(
      config.values.entries.where((e) => e.value.fixed).map((e) => e.key),
    );

    return DbConfigFormState(
      overrides: overrides,
      host: config.getValue(DbConfigFields.fieldHost),
      port: config.getValue(DbConfigFields.fieldPort).toString(),
      dbName: config.getValue(DbConfigFields.fieldDbName),
      user: config.getValue(DbConfigFields.fieldUser),
      password: config.getValue(DbConfigFields.fieldPassword),
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
      overrides: _overrides,
      host: host ?? this.host,
      port: port ?? this.port,
      dbName: dbName ?? this.dbName,
      user: user ?? this.user,
      password: password ?? this.password,
    );
  }

  DbConfigFormState withErrors({
    String? smtpHostError,
    String? smtpPortError,
    String? dbNameError,
    String? userError,
  }) {
    return DbConfigFormState(
      overrides: _overrides,
      host: host,
      port: port,
      user: user,
      password: password,
      dbName: dbName,
      hostError: smtpHostError,
      portError: smtpPortError,
      dbNameError: dbNameError,
      userError: userError,
    );
  }

  bool hasHostOverride() => _overrides.contains(DbConfigFields.fieldHost);
  bool hasPortOverride() => _overrides.contains(DbConfigFields.fieldPort);
  bool hasDbNameOverride() => _overrides.contains(DbConfigFields.fieldDbName);
  bool hasUserOverride() => _overrides.contains(DbConfigFields.fieldUser);
  bool hasPasswordOverride() =>
      _overrides.contains(DbConfigFields.fieldPassword);

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

    return (const SetEquality()).equals(other._overrides, _overrides) &&
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

  LocalConfig<DbConfigFields>? validate() {
    final newState = state.withErrors(
      smtpHostError: state.hasHostOverride()
          ? null
          : state.host == ''
          ? 'Required'
          : null,
      smtpPortError: state.hasPortOverride()
          ? null
          : state.port.isEmpty
          ? 'Required'
          : (int.tryParse(state.port) ?? 0) == 0
          ? 'Invalid Port'
          : null,
      dbNameError: state.hasDbNameOverride()
          ? null
          : state.dbName == ''
          ? 'Required'
          : null,
      userError: state.hasUserOverride()
          ? null
          : state.user == ''
          ? 'Required'
          : null,
    );
    if (newState.hostError == null &&
        newState.portError == null &&
        newState.userError == null &&
        newState.dbNameError == null) {
      final updates = LocalConfig<DbConfigFields>();
      updates.set(DbConfigFields.fieldHost, state.host);
      updates.set(DbConfigFields.fieldPort, state.port);
      updates.set(DbConfigFields.fieldDbName, state.dbName);
      updates.set(DbConfigFields.fieldUser, state.user);
      updates.set(DbConfigFields.fieldPassword, state.password);
      return updates;
    } else {
      emit(newState);
      return null;
    }
  }

  Future<DbConfigCheckResult> checkConfig(
    LocalConfig<DbConfigFields> config,
  ) async {
    final builder = UriBuilder.fromUri(Uri.parse(_instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/db/validate';
    final request = Request('post', builder.build());
    request.body = jsonEncode(config.toMap(_remoteConfig));

    final result = await sendRequest(request);
    if (result is SuccessResponse) {
      final responseMap = (jsonDecode(result.responseString) as Map)
          .cast<String, dynamic>();

      final error = (responseMap['error'] as Map?)?.cast<String, dynamic>();
      final warning = (responseMap['warning'] as Map?)?.cast<String, dynamic>();
      if (error != null) {
        return DbConfigCheckError(
          title: error['msg'],
          message: error['details'],
        );
      } else if (warning != null) {
        if (warning['code'] == 'not_empty') {
          return const DbConfigCheckWarningNotEmpty();
        } else {
          return DbConfigCheckUnknownWarning(code: warning['code']);
        }
      }
      return const DbConfigCheckSuccess();
    } else {
      return DbConfigCheckFailed(error: result.toString());
    }
  }
}

sealed class DbConfigCheckResult {
  const DbConfigCheckResult();
}

class DbConfigCheckSuccess extends DbConfigCheckResult {
  const DbConfigCheckSuccess();
}

class DbConfigCheckFailed extends DbConfigCheckResult {
  final String error;

  DbConfigCheckFailed({required this.error});
}

class DbConfigCheckError extends DbConfigCheckResult {
  final String title;
  final String? message;

  DbConfigCheckError({required this.title, required this.message});
}

class DbConfigCheckWarningNotEmpty extends DbConfigCheckResult {
  const DbConfigCheckWarningNotEmpty();
}

class DbConfigCheckUnknownWarning extends DbConfigCheckResult {
  final String code;
  const DbConfigCheckUnknownWarning({required this.code});
}
