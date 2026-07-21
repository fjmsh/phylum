import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';

class MailConfigFormState {
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
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      fromName: fromName ?? this.fromName,
      fromEmail: fromEmail ?? this.fromEmail,
      instanceUrl: instanceUrl ?? this.instanceUrl,
      // smtpHostError: smtpHostError,
      // smtpPortError: smtpPortError,
      // smtpUsernameError: smtpUsernameError,
      // fromNameError: fromNameError,
      // fromEmailError: fromEmailError,
      // instanceUrlError: instanceUrlError,
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
  MailConfigFormCubit({required MailConfig config})
    : super(
        MailConfigFormState(
          enabled: config.enabled,
          smtpHost: config.smtpHost,
          smtpPort: config.smtpPort.toString(),
          smtpUsername: config.smtpUsername,
          smtpPassword: config.smtpPassword,
          fromName: config.fromName,
          fromEmail: config.fromEmail,
          instanceUrl: config.instanceUrl,
        ),
      );

  void reset(MailConfig config) {
    emit(
      MailConfigFormState(
        enabled: config.enabled,
        smtpHost: config.smtpHost,
        smtpPort: config.smtpPort.toString(),
        smtpUsername: config.smtpUsername,
        smtpPassword: config.smtpPassword,
        fromName: config.fromName,
        fromEmail: config.fromEmail,
        instanceUrl: config.instanceUrl,
      ),
    );
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

  MailConfig? validate() {
    final newState = state.enabled
        ? state.withErrors(
            smtpHostError: state.smtpHost == '' ? 'Required' : null,
            smtpPortError: state.smtpPort.isEmpty
                ? 'Required'
                : (int.tryParse(state.smtpPort) ?? 0) == 0
                ? 'Invalid Port'
                : null,
            smtpUsernameError: state.smtpUsername == '' ? 'Required' : null,
            fromNameError: state.fromName == '' ? 'Required' : null,
            fromEmailError: state.fromEmail.isEmpty
                ? 'Required'
                : EmailValidator.validate(state.fromEmail)
                ? null
                : 'Invalid Email Address',
            instanceUrlError: state.instanceUrl.isEmpty
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
      return MailConfig(
        enabled: state.enabled,
        smtpHost: state.smtpHost,
        smtpPort: int.parse(state.smtpPort),
        smtpUsername: state.smtpUsername,
        smtpPassword: state.smtpPassword,
        fromName: state.fromName,
        fromEmail: state.fromEmail,
        instanceUrl: state.instanceUrl,
      );
    } else {
      emit(newState);
      return null;
    }
  }
}
