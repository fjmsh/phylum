part of '../mail_config_controller.dart';

class _ConfigResponse extends PhylumApiSuccessResponse {
  final MailConfig config;

  _ConfigResponse({required this.config});

  factory _ConfigResponse.fromResponse(Map<String, dynamic> data) {
    return _ConfigResponse(config: MailConfig.fromMap(data));
  }

  @override
  Future process(PhylumAccount account) async {}
}
