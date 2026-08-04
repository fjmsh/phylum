import 'package:collection/collection.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/config/config.dart';

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

  factory OpenIDConfig.creteFromRemoteConfig(
    RemoteConfig<OidcConfigFields> remote,
  ) {
    return OpenIDConfig._(
      fixed: remote.fixed,
      name: remote.getValue(OidcConfigFields.fieldName),
      issuerUrl: remote.getValue(OidcConfigFields.fieldIssuerUrl),
      clientId: remote.getValue(OidcConfigFields.fieldClientId),
      clientSecret: remote.getValue(OidcConfigFields.fieldClientSecret),
      allowUnverifiedEmails: remote.getValue(
        OidcConfigFields.fieldAllowUnverifiedEmails,
      ),
      autoCreateUsers: remote.getValue(OidcConfigFields.fieldAutoCreateUsers),
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

  @override
  String toString() {
    return 'OpenIDConfig(name: $name, '
        'issuerUrl: $issuerUrl, '
        'clientId: $clientId, '
        'clientSecret: $clientSecret, '
        'allowUnverifiedEmails: $allowUnverifiedEmails, '
        'autoCreateUsers: $autoCreateUsers)';
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
