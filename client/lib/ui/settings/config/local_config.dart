part of 'config.dart';

class LocalConfig<C extends ConfigFields> {
  final Map<PrimitiveField, dynamic> values = {};

  LocalConfig();

  void set<T>(PrimitiveField<T> field, T value) {
    values[field] = value;
  }

  T get<T>(PrimitiveField<T> field) {
    return values[field] ?? field.defaultValue;
  }

  Map<String, dynamic> toMap(RemoteConfig<C> config) {
    return config.schema.root.toMap(config.values, values) ?? {};
  }
}
