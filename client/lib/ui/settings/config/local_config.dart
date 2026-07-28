import 'package:phylum/ui/settings/config/remote_config.dart';

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
    return _toMap(config.values, config.schema.root);
  }

  dynamic _toMap(
    Map<PrimitiveField, RemoteValue> remoteValues,
    ConfigField field,
  ) {
    return switch (field) {
      ObjectField() => _objectToMap(remoteValues, field),
      PrimitiveField<dynamic>() => _primitiveValue(remoteValues, field),
      MapField<ConfigField>() => throw UnimplementedError(),
    };
  }

  Map<String, dynamic>? _objectToMap(
    Map<PrimitiveField, RemoteValue> remoteValues,
    ObjectField field,
  ) {
    final map = Map.fromEntries(
      field.fields.entries
          .map((e) {
            final sub = _toMap(remoteValues, e.value);
            if (sub == null) {
              return null;
            }
            return MapEntry(e.key, sub);
          })
          .whereType<MapEntry<String, dynamic>>()
          .toList(growable: false),
    );
    return map.isEmpty ? null : map;
  }

  dynamic _primitiveValue(
    Map<PrimitiveField, RemoteValue> remoteValues,
    PrimitiveField field,
  ) {
    if (remoteValues[field]?.fixed == true) return null;
    if (remoteValues[field]?.value == values[field]) return null;
    return values[field];
  }
}
