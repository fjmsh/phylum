part of '../user_list_controller.dart';

class _UserListRequest extends ApiRequest<PhylumAccount> {
  const _UserListRequest();

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/users/list');
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, _UserListResponse.fromResponse);
  }
}
