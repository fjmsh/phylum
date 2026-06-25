part of 'mail_config_controller.dart';

class _ConfigReadRequest extends ApiRequest<PhylumAccount> {
  const _ConfigReadRequest();

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/config/mail/read');
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, _ConfigResponse.fromResponse);
  }
}
