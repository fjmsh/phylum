part of 'remote_config_controller.dart';

class _ConfigUpdateRequest<T> extends ApiRequest<PhylumAccount> {
  final String _baseRoute;
  final Map<String, dynamic> _config;
  final T Function(Map<String, dynamic>) _parseConfig;

  const _ConfigUpdateRequest({
    required this._baseRoute,
    required this._config,
    required this._parseConfig,
  });

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('$_baseRoute/update');

    final request = Request('post', uri.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'config': _config});
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(
      response,
      (response) => _ConfigResponse.fromResponse(response, _parseConfig),
    );
  }
}
