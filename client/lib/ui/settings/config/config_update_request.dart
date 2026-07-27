part of 'remote_config_controller.dart';

class _ConfigUpdateRequest<T extends ConfigFields>
    extends ApiRequest<PhylumAccount> {
  final String _baseRoute;
  final RemoteConfig<T> _remoteConfig;
  final LocalConfigUpdates<T> _config;

  const _ConfigUpdateRequest({
    required this._baseRoute,
    required this._remoteConfig,
    required this._config,
  });

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('$_baseRoute/update');

    final request = Request('post', uri.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'config': _config.toMapDiff(_remoteConfig)});
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }
}
