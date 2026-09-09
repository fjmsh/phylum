part of 'config.dart';

class RemoteConfig<C extends ConfigFields> {
  final C schema;
  final Set<PrimitiveField> fixed;
  final Map<PrimitiveField, dynamic> values;
  final Map<ProxyObjectField, RemoteConfig> objects;
  final Map<MapField, Map<String, RemoteConfig>> maps;

  RemoteConfig._({
    required this.schema,
    required this.fixed,
    required this.values,
    required this.objects,
    required this.maps,
  });

  factory RemoteConfig.empty(C schema) {
    return RemoteConfig._(
      schema: schema,
      fixed: {},
      values: {},
      objects: {},
      maps: {},
    );
  }

  factory RemoteConfig.fromMap(C schema, Map<String, dynamic> map) {
    final data = (map['config'] as Map).cast<String, dynamic>();
    final fixed = Set.of((map['overrides'] as List).cast<String>());
    return RemoteConfig.fromDataFixed(
      schema,
      fixed: fixed,
      data: data,
      path: "",
    );
  }

  factory RemoteConfig.fromDataFixed(
    C schema, {
    required Set<String> fixed,
    required Map<String, dynamic> data,
    required String path,
  }) {
    final config = RemoteConfig.empty(schema);
    schema.root.parse(config: config, fixed: fixed, path: path, data: data);
    return config;
  }

  T? getValue<T>(PrimitiveField<T> field) {
    return values[field] as T?;
  }

  T getValueOrDefault<T>(PrimitiveField<T> field) {
    final value = (values[field] as T?) ?? field.defaultValue;
    if (!fixed.contains(field) &&
        (value == "" || value == 0 || value == false)) {
      return field.defaultValue;
    }
    return value;
  }

  void setValue<T>(PrimitiveField<T> field, T value) {
    values[field] = value;
  }

  Map<String, RemoteConfig<FC>> getMap<FC extends ConfigFields>(
    MapField<FC> field,
  ) {
    return maps[field]?.cast() ?? const {};
  }

  Iterable<String> getMapKeys<FC extends ConfigFields>(MapField<FC> field) {
    return getMap(field).keys;
  }

  RemoteConfig<FC>? getMapValue<FC extends ConfigFields>(
    MapField<FC> field, {

    required String key,
  }) {
    return getMap(field)[key];
  }

  void setMapValue<FC extends ConfigFields>(
    MapField<FC> field, {
    required String key,
    required RemoteConfig<FC> value,
  }) {
    maps.putIfAbsent(field, () => <String, RemoteConfig<FC>>{})[key] = value;
  }

  void deleteMapEntry<FC extends ConfigFields>(
    MapField<FC> field, {
    required String key,
  }) {
    maps.putIfAbsent(field, () => <String, RemoteConfig<FC>>{}).remove(key);
  }

  RemoteConfig<FC> getObject<FC extends ConfigFields>(
    ProxyObjectField<FC> field,
  ) {
    return objects[field]! as RemoteConfig<FC>;
  }

  RemoteConfig<C> copy() {
    return RemoteConfig._(
      schema: schema,
      values: Map.of(values),
      fixed: Set.of(fixed),
      objects: objects.map((k, v) => MapEntry(k, v.copy())),
      maps: maps.map(
        (k, v) => MapEntry(k, v.map((k, v) => MapEntry(k, v.copy()))),
      ),
    );
  }
}

class FieldDef<T> {
  final String path;
  final T defaultValue;

  const FieldDef({required this.path, required this.defaultValue});

  @override
  bool operator ==(covariant FieldDef other) {
    if (identical(this, other)) return true;
    return path == other.path &&
        defaultValue.runtimeType == other.defaultValue.runtimeType &&
        defaultValue == other.defaultValue;
  }

  @override
  int get hashCode => path.hashCode ^ defaultValue.hashCode;
}
