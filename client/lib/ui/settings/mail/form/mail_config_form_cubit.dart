import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:email_validator/email_validator.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';

class MailConfigFormState {
  final Set<PrimitiveField> _fixed;
  final bool enabled;
  final String smtpHost;
  final String smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String fromName;
  final String fromEmail;
  final String instanceUrl;
  final String? smtpHostError;
  final String? smtpPortError;
  final String? smtpUsernameError;
  final String? fromNameError;
  final String? fromEmailError;
  final String? instanceUrlError;

  MailConfigFormState({
    required this.enabled,
    required this._fixed,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.fromName,
    required this.fromEmail,
    required this.instanceUrl,
    this.smtpHostError,
    this.smtpPortError,
    this.smtpUsernameError,
    this.fromNameError,
    this.fromEmailError,
    this.instanceUrlError,
  });

  factory MailConfigFormState.createFromRemoteConfig(
    RemoteConfig<MailConfigFields> config,
    String instanceUrl,
  ) {
    final remoteInstanceUrl = config.getValue(MailConfigFields.fieldInstance);
    return MailConfigFormState(
      fixed: config.fixed,
      enabled: config.getValue(MailConfigFields.fieldEnabled),
      smtpHost: config.getValue(MailConfigFields.fieldSmtpHost),
      smtpPort: config.getValue(MailConfigFields.fieldSmtpPort).toString(),
      smtpUsername: config.getValue(MailConfigFields.fieldSmtpUsername),
      smtpPassword: config.getValue(MailConfigFields.fieldSmtpPassword),
      fromName: config.getValue(MailConfigFields.fieldFromName),
      fromEmail: config.getValue(MailConfigFields.fieldFromEmail),
      instanceUrl:
          remoteInstanceUrl.isEmpty &&
              !config.fixed.contains(MailConfigFields.fieldInstance)
          ? instanceUrl
          : remoteInstanceUrl,
    );
  }

  MailConfigFormState copyWith({
    bool? enabled,
    String? smtpHost,
    String? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    String? fromName,
    String? fromEmail,
    String? instanceUrl,
  }) {
    return MailConfigFormState(
      enabled: enabled ?? this.enabled,
      fixed: _fixed,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      fromName: fromName ?? this.fromName,
      fromEmail: fromEmail ?? this.fromEmail,
      instanceUrl: instanceUrl ?? this.instanceUrl,
    );
  }

  MailConfigFormState withErrors({
    String? smtpHostError,
    String? smtpPortError,
    String? smtpUsernameError,
    String? fromNameError,
    String? fromEmailError,
    String? instanceUrlError,
  }) {
    return MailConfigFormState(
      enabled: enabled,
      fixed: _fixed,
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      smtpUsername: smtpUsername,
      smtpPassword: smtpPassword,
      fromName: fromName,
      fromEmail: fromEmail,
      instanceUrl: instanceUrl,
      smtpHostError: smtpHostError,
      smtpPortError: smtpPortError,
      smtpUsernameError: smtpUsernameError,
      fromNameError: fromNameError,
      fromEmailError: fromEmailError,
      instanceUrlError: instanceUrlError,
    );
  }

  bool isEnabledFixed() => _fixed.contains(MailConfigFields.fieldEnabled);
  bool isSmtpHostFixed() => _fixed.contains(MailConfigFields.fieldSmtpHost);
  bool isSmtpPortFixed() => _fixed.contains(MailConfigFields.fieldSmtpPort);
  bool isSmtpUsernameFixed() =>
      _fixed.contains(MailConfigFields.fieldSmtpUsername);
  bool isSmtpPasswordFixed() =>
      _fixed.contains(MailConfigFields.fieldSmtpPassword);
  bool isFromNameFixed() => _fixed.contains(MailConfigFields.fieldFromName);
  bool isFromEmailFixed() => _fixed.contains(MailConfigFields.fieldFromEmail);
  bool isInstanceFixed() => _fixed.contains(MailConfigFields.fieldInstance);

  @override
  String toString() {
    return 'MailConfigFormState('
        'enabled: $enabled, '
        'smtpHost: $smtpHost, '
        'smtpHostError: $smtpHostError, '
        'smtpPort: $smtpPort, '
        'smtpPortError: $smtpPortError, '
        'smtpUsername: $smtpUsername, '
        'smtpUsernameError: $smtpUsernameError, '
        'smtpPassword: $smtpPassword, '
        'fromName: $fromName, '
        'fromNameError: $fromNameError, '
        'fromEmail: $fromEmail, '
        'fromEmailError: $fromEmailError, '
        'instanceUrl: $instanceUrl, '
        'instanceUrlError: $instanceUrlError)';
  }

  @override
  bool operator ==(covariant MailConfigFormState other) {
    if (identical(this, other)) return true;

    return other.enabled == enabled &&
        (const SetEquality()).equals(other._fixed, _fixed) &&
        other.smtpHost == smtpHost &&
        other.smtpHostError == smtpHostError &&
        other.smtpPort == smtpPort &&
        other.smtpPortError == smtpPortError &&
        other.smtpUsername == smtpUsername &&
        other.smtpUsernameError == smtpUsernameError &&
        other.smtpPassword == smtpPassword &&
        other.fromName == fromName &&
        other.fromNameError == fromNameError &&
        other.fromEmail == fromEmail &&
        other.fromEmailError == fromEmailError &&
        other.instanceUrl == instanceUrl &&
        other.instanceUrlError == instanceUrlError;
  }

  @override
  int get hashCode {
    return enabled.hashCode ^
        smtpHost.hashCode ^
        smtpHostError.hashCode ^
        smtpPort.hashCode ^
        smtpPortError.hashCode ^
        smtpUsername.hashCode ^
        smtpUsernameError.hashCode ^
        smtpPassword.hashCode ^
        fromName.hashCode ^
        fromNameError.hashCode ^
        fromEmail.hashCode ^
        fromEmailError.hashCode ^
        instanceUrl.hashCode ^
        instanceUrlError.hashCode;
  }
}

class MailConfigFormCubit extends Cubit<MailConfigFormState> {
  final RemoteConfig<MailConfigFields> _remoteConfig;
  MailConfigFormCubit({
    required this._remoteConfig,
    required String instanceUrl,
  }) : super(
         MailConfigFormState.createFromRemoteConfig(_remoteConfig, instanceUrl),
       );

  void reset(RemoteConfig<MailConfigFields> config) {
    emit(MailConfigFormState.createFromRemoteConfig(config, state.instanceUrl));
  }

  set enabled(bool val) {
    emit(state.copyWith(enabled: val));
  }

  set smtpHost(String val) {
    emit(state.copyWith(smtpHost: val));
  }

  set smtpPort(String val) {
    emit(state.copyWith(smtpPort: val));
  }

  set smtpUsername(String val) {
    emit(
      state.copyWith(
        smtpUsername: val,
        fromEmail: state.smtpUsername == state.fromEmail ? val : null,
      ),
    );
  }

  set smtpPassword(String val) {
    emit(state.copyWith(smtpPassword: val));
  }

  set fromEmail(String val) {
    emit(state.copyWith(fromEmail: val));
  }

  set fromName(String val) {
    emit(state.copyWith(fromName: val));
  }

  set instanceUrl(String val) {
    emit(state.copyWith(instanceUrl: val));
  }

  Map<String, dynamic>? validateConfig() {
    final newState = state.enabled
        ? state.withErrors(
            smtpHostError: state.isSmtpHostFixed()
                ? null
                : state.smtpHost == ''
                ? 'Required'
                : null,
            smtpPortError: state.isSmtpPortFixed()
                ? null
                : state.smtpPort.isEmpty
                ? 'Required'
                : (int.tryParse(state.smtpPort) ?? 0) == 0
                ? 'Invalid Port'
                : null,
            smtpUsernameError: state.isSmtpUsernameFixed()
                ? null
                : state.smtpUsername == ''
                ? 'Required'
                : null,
            fromNameError: state.isFromNameFixed()
                ? null
                : state.fromName == ''
                ? 'Required'
                : null,
            fromEmailError:
                state.isFromEmailFixed() ||
                    state.fromEmail.isEmpty ||
                    EmailValidator.validate(state.fromEmail)
                ? null
                : 'Invalid Email Address',
            instanceUrlError: state.isInstanceFixed()
                ? null
                : state.instanceUrl.isEmpty
                ? 'Required'
                : Uri.tryParse(state.instanceUrl) == null
                ? 'Invalid URL'
                : null,
          )
        : state;
    if (newState.smtpHostError == null &&
        newState.smtpPortError == null &&
        newState.smtpUsernameError == null &&
        newState.fromNameError == null &&
        newState.fromEmailError == null &&
        newState.instanceUrlError == null) {
      final local = LocalConfig<MailConfigFields>();
      local.setValue(MailConfigFields.fieldEnabled, state.enabled);
      if (state.enabled) {
        local.setValue(MailConfigFields.fieldSmtpHost, state.smtpHost);
        local.setValue(MailConfigFields.fieldSmtpPort, state.smtpPort);
        local.setValue(MailConfigFields.fieldSmtpUsername, state.smtpUsername);
        local.setValue(MailConfigFields.fieldSmtpPassword, state.smtpPassword);
        local.setValue(MailConfigFields.fieldFromEmail, state.fromEmail);
        local.setValue(MailConfigFields.fieldFromName, state.fromName);
        local.setValue(MailConfigFields.fieldInstance, state.instanceUrl);
      }
      return local.toMap(_remoteConfig);
    } else {
      emit(newState);
      return null;
    }
  }
}
