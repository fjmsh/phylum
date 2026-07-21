part of 'remote_config_controller.dart';

class _ConfigUpdateRequest<T extends Config> extends ApiRequest<PhylumAccount> {
  final String _baseRoute;
  final T _config;

  const _ConfigUpdateRequest({required this._baseRoute, required this._config});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('$_baseRoute/update');

    final request = Request('post', uri.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'config': _config.toMap()});
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }
}
