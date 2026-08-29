import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/ui/setup/auth_cubit.dart';
import 'package:phylum/ui/setup/db/db_config.dart';
import 'package:phylum/ui/setup/db/db_config_form_cubit.dart';
import 'package:phylum/ui/setup/setup_config.dart';
import 'package:phylum/ui/setup/mail_cubit.dart';
import 'package:phylum/ui/setup/user/user_config_form_cubit.dart';

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
  final LocalConfig<DbConfigFields> dbConfig;
  final bool wipeDb;

  SetupStateMail({required this.dbConfig, required this.wipeDb});

  @override
  SetupState previousStep() => const SetupStateDb();
}

class SetupStateAuth extends SetupState {
  final LocalConfig<DbConfigFields> dbConfig;
  final bool wipeDb;
  final LocalConfig<MailConfigFields> mailConfig;

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
  final LocalConfig<DbConfigFields> dbConfig;
  final bool wipeDb;
  final LocalConfig<MailConfigFields> mailConfig;
  final LocalConfig<AuthConfigFields> authConfig;

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
  late final DbConfigFormCubit dbBloc;
  late final MailConfigSetupCubit mailBloc;
  late final AuthConfigSetupCubit authBloc;
  late final UserConfigFormCubit userBloc;

  SetupCubit({required this._instanceUrl, required this._config})
    : super(const SetupStateDb()) {
    dbBloc = DbConfigFormCubit(
      instanceUrl: _instanceUrl,
      remoteConfig: _config.dbConfig,
    );
    mailBloc = MailConfigSetupCubit(
      instanceUrl: _instanceUrl,
      remoteConfig: _config.mailConfig,
    );
    authBloc = AuthConfigSetupCubit(remote: _config.authConfig);
    userBloc = UserConfigFormCubit();
  }

  void previousStep() {
    emit(state.previousStep());
  }

  void configureDb({
    required LocalConfig<DbConfigFields> dbConfig,
    required bool wipeDb,
  }) {
    if (state is SetupStateDb) {
      emit(SetupStateMail(dbConfig: dbConfig, wipeDb: wipeDb));
    }
  }

  void configureMail({required LocalConfig<MailConfigFields> mailConfig}) {
    final state = this.state;
    if (state is SetupStateMail) {
      emit(
        SetupStateAuth(
          dbConfig: state.dbConfig,
          wipeDb: state.wipeDb,
          mailConfig: mailConfig,
        ),
      );
      authBloc.passwordlessLoginEnabled = mailBloc.state.enabled;
      authBloc.cryptBloc.resetEnabled = mailBloc.state.enabled;
    }
  }

  void configureAuth({required LocalConfig<AuthConfigFields> authConfig}) {
    final state = this.state;
    if (state is SetupStateAuth) {
      emit(
        SetupStateUser(
          dbConfig: state.dbConfig,
          wipeDb: state.wipeDb,
          mailConfig: state.mailConfig,
          authConfig: authConfig,
        ),
      );
      userBloc.passwordRequired =
          authBloc.state.passwordBackend == PasswordBackend.crypt;
    }
  }
}
