part of 'config.dart';

class LocalConfig<C extends ConfigFields> {
  final Map<PrimitiveField, dynamic> values = {};
  final Map<MapField, LocalConfig> objects = {};
  final Map<MapField, Map<String, LocalConfig>> maps = {};

  LocalConfig();

  void setValue<T>(PrimitiveField<T> field, T value) {
    values[field] = value;
  }

  T? getValue<T>(PrimitiveField<T> field) {
    return values[field];
  }

  void addMapEntry<MC extends ConfigFields>(
    MapField<MC> field,
    key,
    LocalConfig<MC> value,
  ) {
    maps.putIfAbsent(field, () => {})[key] = value;
  }

  Map<String, dynamic> toMap(RemoteConfig<C> config) {
    final values = Map.of(this.values);
    for (final field in config.fixed) {
      values.remove(field);
    }
    return config.schema.root.toMap(config, this) ?? {};
  }
}
