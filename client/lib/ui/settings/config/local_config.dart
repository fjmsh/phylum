part of 'config.dart';

class LocalConfig<C extends ConfigFields> {
  final Map<PrimitiveField, dynamic> values = {};

  LocalConfig();

  void setValue<T>(PrimitiveField<T> field, T value) {
    values[field] = value;
  }

  T getValue<T>(PrimitiveField<T> field) {
    return values[field] ?? field.defaultValue;
  }

  Map<String, dynamic> toMap(RemoteConfig<C> config) {
    final values = Map.of(this.values);
    for (final field in config.fixed) {
      values[field] = null;
    }
    return config.schema.root.toMap(config.values, values) ?? {};
  }
}
