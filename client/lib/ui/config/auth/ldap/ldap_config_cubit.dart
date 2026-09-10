import 'package:bloc/bloc.dart';
import 'package:phylum/ui/config/config.dart';

import 'ldap_config.dart';

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
    RemoteConfig<LdapConfigFields> remote,
  ) {
    return LdapConfigState(
      fixed: remote.fixed,
      serverUrl: remote.getValueOrDefault(LdapConfigFields.fieldUrl),
      starttls: remote.getValueOrDefault(LdapConfigFields.fieldStarttls),
      autoCreateUsers: remote.getValueOrDefault(
        LdapConfigFields.fieldAutoCreateUsers,
      ),
      useFilter: remote.getValueOrDefault(LdapConfigFields.fieldUseFilter),
      dnTemplate: remote.getValueOrDefault(LdapConfigFields.fieldDnTemplate),
      filterBindDn: remote.getValueOrDefault(
        LdapConfigFields.fieldFilterBindDn,
      ),
      filterBindPassword: remote.getValueOrDefault(
        LdapConfigFields.fieldFilterBindPassword,
      ),
      filterBaseDn: remote.getValueOrDefault(
        LdapConfigFields.fieldFilterBaseDn,
      ),
      filterTemplate: remote.getValueOrDefault(
        LdapConfigFields.fieldFilterTemplate,
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

  bool get hasErrors =>
      serverUrlError != null ||
      dnTemplateError != null ||
      filterBindDnError != null ||
      filterBaseDnError != null ||
      filterTemplateError != null;

  bool isServerUrlFixed() => _fixed.contains(LdapConfigFields.fieldUrl);
  bool isStarttlsFixed() => _fixed.contains(LdapConfigFields.fieldStarttls);
  bool isAutoCreateUsersFixed() =>
      _fixed.contains(LdapConfigFields.fieldAutoCreateUsers);
  bool isUseFilterFixed() => _fixed.contains(LdapConfigFields.fieldUseFilter);
  bool isDnTemplateFixed() => _fixed.contains(LdapConfigFields.fieldDnTemplate);
  bool isFilterBindDnFixed() =>
      _fixed.contains(LdapConfigFields.fieldFilterBindDn);
  bool isFilterBindPasswordFixed() =>
      _fixed.contains(LdapConfigFields.fieldFilterBindPassword);
  bool isFilterBaseDnFixed() =>
      _fixed.contains(LdapConfigFields.fieldFilterBaseDn);
  bool isFilterTemplateFixed() =>
      _fixed.contains(LdapConfigFields.fieldFilterTemplate);

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
  final RemoteConfig<LdapConfigFields> _remote;
  LdapConfigCubit({required this._remote})
    : super(LdapConfigState.createFromRemoteConfig(_remote));

  void reset() {
    emit(LdapConfigState.createFromRemoteConfig(_remote));
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

  LocalConfig<LdapConfigFields>? validate() {
    final local = LocalConfig<LdapConfigFields>();

    local.setValue<String>(LdapConfigFields.fieldUrl, state.serverUrl);
    local.setValue<bool>(LdapConfigFields.fieldStarttls, state.starttls);
    local.setValue<bool>(
      LdapConfigFields.fieldAutoCreateUsers,
      state.autoCreateUsers,
    );
    local.setValue<bool>(LdapConfigFields.fieldUseFilter, state.useFilter);
    if (state.useFilter) {
      local.setValue<String>(
        LdapConfigFields.fieldFilterBindDn,
        state.filterBindDn,
      );
      local.setValue<String>(
        LdapConfigFields.fieldFilterBindPassword,
        state.filterBindPassword,
      );
      local.setValue<String>(
        LdapConfigFields.fieldFilterBaseDn,
        state.filterBaseDn,
      );
      local.setValue<String>(
        LdapConfigFields.fieldFilterTemplate,
        state.filterTemplate,
      );
    } else {
      local.setValue<String>(
        LdapConfigFields.fieldDnTemplate,
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

    final dnTemplateError = state.useFilter
        ? null
        : state.isDnTemplateFixed()
        ? null
        : state.dnTemplate.isEmpty
        ? 'Required'
        : null;

    final filterBindDnError = !state.useFilter
        ? null
        : state.isFilterBindDnFixed()
        ? null
        : state.filterBindDn.isEmpty
        ? 'Required'
        : null;

    final filterBaseDnError = !state.useFilter
        ? null
        : state.isFilterBaseDnFixed()
        ? null
        : state.filterBaseDn.isEmpty
        ? 'Required'
        : null;

    final filterTemplateError = !state.useFilter
        ? null
        : state.isFilterTemplateFixed()
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

    if (newState.hasErrors) {
      emit(newState);
      return null;
    }
    return local;
  }
}
