part of 'remote_config_controller.dart';

class _ConfigResponse<T> extends PhylumApiSuccessResponse {
  final T config;

  _ConfigResponse({required this.config});

  factory _ConfigResponse.fromResponse(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic> data) fromMap,
  ) {
    return _ConfigResponse(config: fromMap(data));
  }

  @override
  Future process(PhylumAccount account) async {}
}
