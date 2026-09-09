import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:phylum/ui/config/auth/auth_config.dart';
import 'package:phylum/ui/config/config.dart';

class OpenIDConfig {
  final Set<PrimitiveField> _fixed;
  final String name;
  final String issuerUrl;
  final String clientId;
  final String clientSecret;
  final bool allowUnverifiedEmails;
  final bool autoCreateUsers;
  final String? nameError;
  final String? issuerUrlError;
  final String? clientIdError;
  final String? clientSecretError;

  OpenIDConfig._({
    required this._fixed,
    required this.name,
    required this.issuerUrl,
    required this.clientId,
    required this.clientSecret,
    required this.allowUnverifiedEmails,
    required this.autoCreateUsers,
    this.nameError,
    this.issuerUrlError,
    this.clientIdError,
    this.clientSecretError,
  });

  factory OpenIDConfig.createFromConfig(
    RemoteConfig<OpenidConfigFields> remote,
  ) {
    return OpenIDConfig._(
      fixed: remote.fixed,
      name: remote.getValueOrDefault(OpenidConfigFields.fieldName),
      issuerUrl: remote.getValueOrDefault(OpenidConfigFields.fieldIssuerUrl),
      clientId: remote.getValueOrDefault(OpenidConfigFields.fieldClientId),
      clientSecret: remote.getValueOrDefault(
        OpenidConfigFields.fieldClientSecret,
      ),
      allowUnverifiedEmails: remote.getValueOrDefault(
        OpenidConfigFields.fieldAllowUnverifiedEmails,
      ),
      autoCreateUsers: remote.getValueOrDefault(
        OpenidConfigFields.fieldAutoCreateUsers,
      ),
    );
  }

  OpenIDConfig copyWith({
    String? name,
    String? issuerUrl,
    String? clientId,
    String? clientSecret,
    bool? allowUnverifiedEmails,
    bool? autoCreateUsers,
  }) => OpenIDConfig._(
    fixed: _fixed,
    name: name ?? this.name,
    issuerUrl: issuerUrl ?? this.issuerUrl,
    clientId: clientId ?? this.clientId,
    clientSecret: clientSecret ?? this.clientSecret,
    allowUnverifiedEmails: allowUnverifiedEmails ?? this.allowUnverifiedEmails,
    autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
  );

  OpenIDConfig copyWithErrors({
    String? nameError,
    String? issuerUrlError,
    String? clientIdError,
    String? clientSecretError,
  }) => OpenIDConfig._(
    fixed: _fixed,
    name: name,
    issuerUrl: issuerUrl,
    clientId: clientId,
    clientSecret: clientSecret,
    allowUnverifiedEmails: allowUnverifiedEmails,
    autoCreateUsers: autoCreateUsers,
    nameError: nameError,
    issuerUrlError: issuerUrlError,
    clientIdError: clientIdError,
    clientSecretError: clientSecretError,
  );

  bool get hasErrors =>
      nameError != null ||
      issuerUrlError != null ||
      clientIdError != null ||
      clientSecretError != null;

  LocalConfig<OpenidConfigFields> toLocalConfig() {
    return LocalConfig()
      ..setValue<String>(OpenidConfigFields.fieldName, name)
      ..setValue<String>(OpenidConfigFields.fieldIssuerUrl, issuerUrl)
      ..setValue<String>(OpenidConfigFields.fieldClientId, clientId)
      ..setValue<String>(OpenidConfigFields.fieldClientSecret, clientSecret)
      ..setValue<bool>(
        OpenidConfigFields.fieldAllowUnverifiedEmails,
        allowUnverifiedEmails,
      )
      ..setValue<bool>(
        OpenidConfigFields.fieldAutoCreateUsers,
        autoCreateUsers,
      );
  }

  bool get hasFixedFields => _fixed.isNotEmpty;
  bool get isNameFixed => _fixed.contains(OpenidConfigFields.fieldName);
  bool get isIssuerUrlFixed =>
      _fixed.contains(OpenidConfigFields.fieldIssuerUrl);
  bool get isClientIdFixed => _fixed.contains(OpenidConfigFields.fieldClientId);
  bool get isClientSecretFixed =>
      _fixed.contains(OpenidConfigFields.fieldClientSecret);
  bool get isAllowUnverifiedEmailsFixed =>
      _fixed.contains(OpenidConfigFields.fieldAllowUnverifiedEmails);
  bool get isAutoCreateUsersFixed =>
      _fixed.contains(OpenidConfigFields.fieldAutoCreateUsers);

  @override
  String toString() {
    return 'OpenIDConfig('
        'name: $name ($isNameFixed), '
        'issuerUrl: $issuerUrl ($isIssuerUrlFixed), '
        'clientId: $clientId ($isClientIdFixed), '
        'clientSecret: $clientSecret ($isClientSecretFixed), '
        'allowUnverifiedEmails: $allowUnverifiedEmails ($isAllowUnverifiedEmailsFixed), '
        'autoCreateUsers: $autoCreateUsers ($isAutoCreateUsersFixed))';
  }

  @override
  bool operator ==(covariant OpenIDConfig other) {
    if (identical(this, other)) return true;

    return const DeepCollectionEquality().equals(_fixed, other._fixed) &&
        other.name == name &&
        other.issuerUrl == issuerUrl &&
        other.clientId == clientId &&
        other.clientSecret == clientSecret &&
        other.allowUnverifiedEmails == allowUnverifiedEmails &&
        other.autoCreateUsers == autoCreateUsers &&
        other.nameError == nameError &&
        other.issuerUrlError == issuerUrlError &&
        other.clientIdError == clientIdError &&
        other.clientSecretError == clientSecretError;
  }

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(_fixed) ^
      name.hashCode ^
      issuerUrl.hashCode ^
      clientId.hashCode ^
      clientSecret.hashCode ^
      allowUnverifiedEmails.hashCode ^
      autoCreateUsers.hashCode ^
      nameError.hashCode ^
      issuerUrlError.hashCode ^
      clientIdError.hashCode ^
      clientSecret.hashCode;
}

class OpenIDConfigFormCubit extends Cubit<OpenIDConfig> {
  OpenIDConfigFormCubit({required OpenIDConfig config}) : super(config);

  set name(String val) {
    emit(state.copyWith(name: val));
  }

  set issuerUrl(String val) {
    emit(state.copyWith(issuerUrl: val));
  }

  set clientId(String val) {
    emit(state.copyWith(clientId: val));
  }

  set clientSecret(String val) {
    emit(state.copyWith(clientSecret: val));
  }

  set allowUnverifiedEmails(bool val) {
    emit(state.copyWith(allowUnverifiedEmails: val));
  }

  set autoCreateUsers(bool val) {
    emit(state.copyWith(autoCreateUsers: val));
  }

  LocalConfig<OpenidConfigFields>? validate() {
    final issuerUrl = Uri.tryParse(state.issuerUrl);

    final newState = state.copyWithErrors(
      nameError: state.isNameFixed
          ? null
          : state.name.isEmpty
          ? 'Required'
          : null,
      issuerUrlError: state.isIssuerUrlFixed
          ? null
          : state.issuerUrl.isEmpty
          ? 'Required'
          : issuerUrl == null || !issuerUrl.hasScheme || !issuerUrl.hasAuthority
          ? 'Invalid URL'
          : null,
      clientIdError: state.isClientIdFixed
          ? null
          : state.clientId.isEmpty
          ? 'Required'
          : null,
      clientSecretError: state.isClientSecretFixed
          ? null
          : state.clientSecret.isEmpty
          ? 'Required'
          : null,
    );
    if (newState.hasErrors) {
      emit(newState);
      return null;
    }
    return state.toLocalConfig();
  }
}
