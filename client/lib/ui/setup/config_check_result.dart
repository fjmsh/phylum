sealed class ConfigCheckResult {
  const ConfigCheckResult();
}

class ConfigInvalid extends ConfigCheckResult {
  final String? error;

  const ConfigInvalid({this.error});
}

sealed class ConfigValid extends ConfigCheckResult {
  final Map<String, dynamic> config;

  const ConfigValid({required this.config});
}

class ConfigCheckSuccess extends ConfigValid {
  const ConfigCheckSuccess({required super.config});
}

class ConfigCheckError extends ConfigValid {
  final String? title;
  final String? message;

  ConfigCheckError({required super.config, this.title, this.message});
}

class ConfigCheckWarning extends ConfigValid {
  final String code;

  const ConfigCheckWarning({required super.config, required this.code});
}
