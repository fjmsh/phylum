import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/config/auth/password/password_config.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

import 'auth/auth_setup_cubit.dart';
import 'auth/crypt_setup_cubit.dart';
import 'db/db_setup_cubit.dart';
import 'mail_setup_cubit.dart';
import 'setup_config.dart';
import 'user/user_config_form_cubit.dart';

sealed class SetupState {
  const SetupState();

  bool get hasPrevious => true;
  bool get hasNext => true;

  SetupState previousStep();
}

class SetupStateDb extends SetupState {
  const SetupStateDb();

  @override
  bool get hasPrevious => false;

  @override
  SetupState previousStep() => this;
}

class SetupStateMail extends SetupState {
  final Map<String, dynamic> dbConfig;
  final bool wipeDb;

  SetupStateMail({required this.dbConfig, required this.wipeDb});

  @override
  SetupState previousStep() => const SetupStateDb();
}

class SetupStateAuth extends SetupState {
  final Map<String, dynamic> dbConfig;
  final bool wipeDb;
  final Map<String, dynamic> mailConfig;

  SetupStateAuth({
    required this.dbConfig,
    required this.wipeDb,
    required this.mailConfig,
  });

  @override
  SetupState previousStep() =>
      SetupStateMail(dbConfig: dbConfig, wipeDb: wipeDb);
}

class SetupStateUser extends SetupState {
  final Map<String, dynamic> dbConfig;
  final bool wipeDb;
  final Map<String, dynamic> mailConfig;
  final Map<String, dynamic> authConfig;

  SetupStateUser({
    required this.dbConfig,
    required this.wipeDb,
    required this.mailConfig,
    required this.authConfig,
  });

  @override
  bool get hasNext => false;

  @override
  SetupState previousStep() => SetupStateAuth(
    dbConfig: dbConfig,
    wipeDb: wipeDb,
    mailConfig: mailConfig,
  );
}

class SetupCubit extends Cubit<SetupState> {
  final String _instanceUrl;
  final SetupConfig _config;
  late final DbSetupCubit dbBloc;
  late final MailSetupCubit mailBloc;
  late final AuthSetupCubit authBloc;
  late final UserConfigFormCubit userBloc;

  SetupCubit({required this._instanceUrl, required this._config})
    : super(const SetupStateDb()) {
    dbBloc = DbSetupCubit(
      instanceUrl: _instanceUrl,
      remoteConfig: _config.dbConfig,
    );
    mailBloc = MailSetupCubit(
      instanceUrl: _instanceUrl,
      remote: _config.mailConfig,
    );
    authBloc = AuthSetupCubit(
      instanceUrl: _instanceUrl,
      remote: _config.authConfig,
      createCryptConfigCubit: (remote) =>
          CryptSetupCubit(instanceUrl: _instanceUrl, remote: remote),
    );
    userBloc = UserConfigFormCubit();
  }

  void previousStep() {
    emit(state.previousStep());
  }

  void configureDb({
    required Map<String, dynamic> config,
    required bool wipeDb,
  }) {
    if (state is SetupStateDb) {
      emit(SetupStateMail(dbConfig: config, wipeDb: wipeDb));
    }
  }

  void configureMail({required Map<String, dynamic> config}) {
    final state = this.state;
    if (state is SetupStateMail) {
      emit(
        SetupStateAuth(
          dbConfig: state.dbConfig,
          wipeDb: state.wipeDb,
          mailConfig: config,
        ),
      );
      authBloc.mailEnabled = mailBloc.state.enabled;
      authBloc.passwordlessLoginEnabled = mailBloc.state.enabled;
      authBloc.passwordBloc.resetEnabled = mailBloc.state.enabled;
    }
  }

  void configureAuth({required Map<String, dynamic> config}) {
    final state = this.state;
    if (state is SetupStateAuth) {
      emit(
        SetupStateUser(
          dbConfig: state.dbConfig,
          wipeDb: state.wipeDb,
          mailConfig: state.mailConfig,
          authConfig: config,
        ),
      );
      userBloc.passwordRequired =
          authBloc.passwordBloc.state.passwordBackend == PasswordBackend.crypt;
    }
  }

  Future<FinalizeResult> configureUser({
    required Map<String, dynamic> userConfig,
  }) async {
    final state = this.state;
    if (state is! SetupStateUser) {
      return const FinalizeError(title: 'Not at the right step');
    }

    final builder = UriBuilder.fromUri(Uri.parse(_instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/finalize';
    final request = Request('post', builder.build());
    final data = {
      'config': {
        'db': state.dbConfig,
        'mail': state.mailConfig,
        'auth': state.authConfig,
      },
      'user': userConfig,
      'options': {
        'db': {'wipe': state.wipeDb},
      },
    };

    request.body = jsonEncode(data);

    final result = await sendRequest(request);
    switch (result) {
      case ServerOffline():
        return const FinalizeError(title: 'Unable to reach server');
      case ClientError(error: String err):
        return FinalizeError(title: 'Client Erorr', message: err);
      case ErrorResponse(error: String err):
        return FinalizeError(title: 'Server Erorr', message: err);
      case SuccessResponse():
        final responseMap = (jsonDecode(result.responseString) as Map)
            .cast<String, dynamic>();

        final error = (responseMap['error'] as Map?)?.cast<String, dynamic>();
        if (error != null) {
          return FinalizeError(title: error['msg'], message: error['details']);
        }
        return const FinalizeSuccess();
    }
  }
}

sealed class FinalizeResult {
  const FinalizeResult();
}

class FinalizeSuccess extends FinalizeResult {
  const FinalizeSuccess();
}

class FinalizeError extends FinalizeResult {
  final String title;
  final String? message;

  const FinalizeError({required this.title, this.message});
}
