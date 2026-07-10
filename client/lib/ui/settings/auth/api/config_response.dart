part of '../auth_config_controller.dart';

class _ConfigResponse extends PhylumApiSuccessResponse {
  final AuthConfig config;

  _ConfigResponse({required this.config});

  factory _ConfigResponse.fromResponse(Map<String, dynamic> data) {
    return _ConfigResponse(config: AuthConfig.fromMap(data));
  }

  @override
  Future process(PhylumAccount account) async {}
}
