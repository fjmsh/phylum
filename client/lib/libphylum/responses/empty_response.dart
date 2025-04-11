part of 'responses.dart';

class EmptyResponse extends PhylumApiSuccessResponse {
  const EmptyResponse();

  factory EmptyResponse.fromResponse(Map<String, dynamic> data) => const EmptyResponse();

  @override
  Future process(PhylumAccount account) async {}
}
