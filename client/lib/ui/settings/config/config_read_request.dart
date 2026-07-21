part of 'remote_config_controller.dart';

class _ConfigReadRequest<T> extends ApiRequest<PhylumAccount> {
  final String _baseRoute;
  final T Function(Map<String, dynamic>) _parseConfig;

  const _ConfigReadRequest({
    required this._baseRoute,
    required this._parseConfig,
  });

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('$_baseRoute/read');
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(
      response,
      (data) => _ConfigResponse.fromResponse(data, _parseConfig),
    );
  }
}
