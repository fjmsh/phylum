import 'package:bloc/bloc.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/config/config.dart';

class LdapConfigState {
  final Set<PrimitiveField> _fixed;
  final String serverUrl;
  final bool starttls;
  final bool autoCreateUsers;
  final bool useFilter;
  final String dnTemplate;
  final String filterBindDn;
  final String filterBindPassword;
  final String filterBaseDn;
  final String filterTemplate;
  final String? serverUrlError;
  final String? dnTemplateError;
  final String? filterBindDnError;
  final String? filterBaseDnError;
  final String? filterTemplateError;

  LdapConfigState({
    required this._fixed,
    required this.serverUrl,
    required this.starttls,
    required this.autoCreateUsers,
    required this.useFilter,
    required this.dnTemplate,
    required this.filterBindDn,
    required this.filterBindPassword,
    required this.filterBaseDn,
    required this.filterTemplate,
    this.serverUrlError,
    this.dnTemplateError,
    this.filterBindDnError,
    this.filterBaseDnError,
    this.filterTemplateError,
  });

  factory LdapConfigState.createFromRemoteConfig(
    RemoteConfig<AuthConfigFields> remote,
  ) {
    return LdapConfigState(
      fixed: remote.fixed,
      serverUrl: remote.getValue(AuthConfigFields.fieldPasswordLdapUrl),
      starttls: remote.getValue(AuthConfigFields.fieldPasswordLdapStarttls),
      autoCreateUsers: remote.getValue(
        AuthConfigFields.fieldPasswordLdapAutoCreateUsers,
      ),
      useFilter: remote.getValue(AuthConfigFields.fieldPasswordLdapUseFilter),
      dnTemplate: remote.getValue(AuthConfigFields.fieldPasswordLdapDnTemplate),
      filterBindDn: remote.getValue(
        AuthConfigFields.fieldPasswordLdapFilterBindDn,
      ),
      filterBindPassword: remote.getValue(
        AuthConfigFields.fieldPasswordLdapFilterBindPassword,
      ),
      filterBaseDn: remote.getValue(
        AuthConfigFields.fieldPasswordLdapFilterBaseDn,
      ),
      filterTemplate: remote.getValue(
        AuthConfigFields.fieldPasswordLdapFilterTemplate,
      ),
    );
  }

  LdapConfigState copyWith({
    String? serverUrl,
    bool? starttls,
    bool? autoCreateUsers,
    bool? useFilter,
    String? dnTemplate,
    String? filterBindDn,
    String? filterBindPassword,
    String? filterBaseDn,
    String? filterTemplate,
  }) => LdapConfigState(
    fixed: _fixed,
    serverUrl: serverUrl ?? this.serverUrl,
    starttls: starttls ?? this.starttls,
    autoCreateUsers: autoCreateUsers ?? this.autoCreateUsers,
    useFilter: useFilter ?? this.useFilter,
    dnTemplate: dnTemplate ?? this.dnTemplate,
    filterBindDn: filterBindDn ?? this.filterBindDn,
    filterBindPassword: filterBindPassword ?? this.filterBindPassword,
    filterBaseDn: filterBaseDn ?? this.filterBaseDn,
    filterTemplate: filterTemplate ?? this.filterTemplate,
  );

  LdapConfigState copyWithErrors({
    String? serverUrlError,
    String? dnTemplateError,
    String? filterBindDnError,
    String? filterBaseDnError,
    String? filterTemplateError,
  }) => LdapConfigState(
    fixed: _fixed,
    serverUrl: serverUrl,
    starttls: starttls,
    autoCreateUsers: autoCreateUsers,
    useFilter: useFilter,
    dnTemplate: dnTemplate,
    filterBindDn: filterBindDn,
    filterBindPassword: filterBindPassword,
    filterBaseDn: filterBaseDn,
    filterTemplate: filterTemplate,
    serverUrlError: serverUrlError ?? this.serverUrlError,
    dnTemplateError: dnTemplateError ?? this.dnTemplateError,
    filterBindDnError: filterBindDnError ?? this.filterBindDnError,
    filterBaseDnError: filterBaseDnError ?? this.filterBaseDnError,
    filterTemplateError: filterTemplateError ?? this.filterTemplateError,
  );

  bool isServerUrlFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapUrl);
  bool isStarttlsFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapStarttls);
  bool isAutoCreateUsersFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapAutoCreateUsers);
  bool isUseFilterFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapUseFilter);
  bool isDnTemplateFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapDnTemplate);
  bool isFilterBindDnFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapFilterBindDn);
  bool isFilterBindPasswordFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapFilterBindPassword);
  bool isFilterBaseDnFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapFilterBaseDn);
  bool isFilterTemplateFixed() =>
      _fixed.contains(AuthConfigFields.fieldPasswordLdapFilterTemplate);

  @override
  bool operator ==(covariant LdapConfigState other) {
    if (identical(this, other)) return true;
    return serverUrl == other.serverUrl &&
        starttls == other.starttls &&
        autoCreateUsers == other.autoCreateUsers &&
        useFilter == other.useFilter &&
        dnTemplate == other.dnTemplate &&
        filterBindDn == other.filterBindDn &&
        filterBindPassword == other.filterBindPassword &&
        filterBaseDn == other.filterBaseDn &&
        filterTemplate == other.filterTemplate &&
        serverUrlError == other.serverUrlError &&
        dnTemplateError == other.dnTemplateError &&
        filterBindDnError == other.filterBindDnError &&
        filterBaseDnError == other.filterBaseDnError &&
        filterTemplateError == other.filterTemplateError;
  }

  @override
  int get hashCode =>
      serverUrl.hashCode ^
      starttls.hashCode ^
      autoCreateUsers.hashCode ^
      useFilter.hashCode ^
      dnTemplate.hashCode ^
      filterBindDn.hashCode ^
      filterBindPassword.hashCode ^
      filterBaseDn.hashCode ^
      filterTemplate.hashCode ^
      serverUrlError.hashCode ^
      dnTemplateError.hashCode ^
      filterBindDnError.hashCode ^
      filterBaseDnError.hashCode ^
      filterTemplateError.hashCode;
}

class LdapConfigCubit extends Cubit<LdapConfigState> {
  LdapConfigCubit({required RemoteConfig<AuthConfigFields> remote})
    : super(LdapConfigState.createFromRemoteConfig(remote));

  void reset(RemoteConfig<AuthConfigFields> remote) {
    emit(LdapConfigState.createFromRemoteConfig(remote));
  }

  set serverUrl(String val) {
    emit(state.copyWith(serverUrl: val));
  }

  set starttls(bool val) {
    emit(state.copyWith(starttls: val));
  }

  set autoCreateUsers(bool val) {
    emit(state.copyWith(autoCreateUsers: val));
  }

  set useFilter(bool val) {
    emit(state.copyWith(useFilter: val));
  }

  set dnTemplate(String val) {
    emit(state.copyWith(dnTemplate: val));
  }

  set filterBindDn(String val) {
    emit(state.copyWith(filterBindDn: val));
  }

  set filterBindPassword(String val) {
    emit(state.copyWith(filterBindPassword: val));
  }

  set filterBaseDn(String val) {
    emit(state.copyWith(filterBaseDn: val));
  }

  set filterTemplate(String val) {
    emit(state.copyWith(filterTemplate: val));
  }

  LocalConfig<AuthConfigFields>? validate() {
    final local = LocalConfig<AuthConfigFields>();

    local.setValue<String>(
      AuthConfigFields.fieldPasswordLdapUrl,
      state.serverUrl,
    );
    local.setValue<bool>(
      AuthConfigFields.fieldPasswordLdapStarttls,
      state.starttls,
    );
    local.setValue<bool>(
      AuthConfigFields.fieldPasswordLdapAutoCreateUsers,
      state.autoCreateUsers,
    );
    local.setValue<bool>(
      AuthConfigFields.fieldPasswordLdapUseFilter,
      state.useFilter,
    );
    if (state.useFilter) {
      local.setValue<String>(
        AuthConfigFields.fieldPasswordLdapFilterBindDn,
        state.filterBindDn,
      );
      local.setValue<String>(
        AuthConfigFields.fieldPasswordLdapFilterBindPassword,
        state.filterBindPassword,
      );
      local.setValue<String>(
        AuthConfigFields.fieldPasswordLdapFilterBaseDn,
        state.filterBaseDn,
      );
      local.setValue<String>(
        AuthConfigFields.fieldPasswordLdapFilterTemplate,
        state.filterTemplate,
      );
    } else {
      local.setValue<String>(
        AuthConfigFields.fieldPasswordLdapDnTemplate,
        state.dnTemplate,
      );
    }

    final serverUri = Uri.tryParse(state.serverUrl);
    final serverUrlError = state.isServerUrlFixed()
        ? null
        : state.serverUrl.isEmpty
        ? 'Required'
        : serverUri == null
        ? 'Invalid URL'
        : serverUri.scheme != 'ldap' && serverUri.scheme != 'ldaps'
        ? 'Scheme must be ldap:// or ldaps://'
        : null;

    final dnTemplateError = state.isDnTemplateFixed()
        ? null
        : state.dnTemplate.isEmpty
        ? 'Required'
        : null;

    final filterBindDnError = state.isFilterBindDnFixed()
        ? null
        : state.filterBindDn.isEmpty
        ? 'Required'
        : null;

    final filterBaseDnError = state.isFilterBaseDnFixed()
        ? null
        : state.filterBaseDn.isEmpty
        ? 'Required'
        : null;

    final filterTemplateError = state.isFilterTemplateFixed()
        ? null
        : state.filterTemplate.isEmpty
        ? 'Required'
        : null;

    final newState = state.copyWithErrors(
      serverUrlError: serverUrlError,
      dnTemplateError: dnTemplateError,
      filterBindDnError: filterBindDnError,
      filterBaseDnError: filterBaseDnError,
      filterTemplateError: filterTemplateError,
    );

    if (state == newState) {
      return local;
    } else {
      emit(newState);
      return null;
    }
  }
}
