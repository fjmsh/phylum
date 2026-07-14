part of 'remote_config_controller.dart';

class _ConfigReadRequest<T> extends ApiRequest<PhylumAccount> {
  final String endpoint;
  final T Function(Map<String, dynamic>) parseConfig;

  const _ConfigReadRequest({required this.endpoint, required this.parseConfig});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder(endpoint);
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(
      response,
      (data) => _ConfigResponse.fromResponse(data, parseConfig),
    );
  }
}
