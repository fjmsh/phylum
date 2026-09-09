part of 'config.dart';

abstract class ConfigFields {
  ObjectField get root;

  const ConfigFields();
}

sealed class ConfigField {
  const ConfigField();

  void parse({
    required RemoteConfig config,
    required Set<String> fixed,
    required String path,
    required dynamic data,
  });

  dynamic toMap<C extends ConfigFields>(
    RemoteConfig<C> remote,
    LocalConfig<C> local,
  );
}

class ObjectField extends ConfigField {
  final Map<String, ConfigField> fields;

  const ObjectField({required this.fields});

  @override
  void parse({
    required RemoteConfig config,
    required Set<String> fixed,
    required String path,
    required dynamic data,
  }) {
    data = (data as Map).cast<String, dynamic>();
    for (final entry in fields.entries) {
      entry.value.parse(
        config: config,
        fixed: fixed,
        path: path.isEmpty ? entry.key : "$path.${entry.key}",
        data: data[entry.key],
      );
    }
  }

  @override
  Map<String, dynamic>? toMap<C extends ConfigFields>(
    RemoteConfig<C> remote,
    LocalConfig<C> local,
  ) {
    final map = Map.fromEntries(
      fields.entries
          .map((e) {
            final sub = e.value.toMap(remote, local);
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
}

class PrimitiveField<T> extends ConfigField {
  final T defaultValue;
  final dynamic Function(T)? toPrimitive;
  final T Function(dynamic)? fromPrimitive;

  PrimitiveField(this.defaultValue, {this.toPrimitive, this.fromPrimitive});

  @override
  void parse({
    required RemoteConfig config,
    required Set<String> fixed,
    required String path,
    required dynamic data,
  }) {
    config.values[this] = fromPrimitive?.call(data) ?? data;
    if (fixed.contains(path)) {
      config.fixed.add(this);
    }
  }

  @override
  dynamic toMap<C extends ConfigFields>(
    RemoteConfig<C> remote,
    LocalConfig<C> local,
  ) {
    final remoteValue = remote.getValue(this);
    final localValue = local.getValue(this);
    if (localValue == null || localValue == remoteValue) return null;
    return toPrimitive?.call(localValue) ?? localValue;
  }
}

class MapField<Cfg extends ConfigFields> extends ConfigField {
  final Cfg schema;

  MapField({required this.schema});

  @override
  void parse({
    required RemoteConfig config,
    required Set<String> fixed,
    required String path,
    required dynamic data,
  }) {
    data = (data as Map).cast<String, dynamic>();

    for (final entry in data.entries) {
      config.maps.putIfAbsent(
        this,
        () => {},
      )[entry.key] = RemoteConfig<Cfg>.fromDataFixed(
        schema,
        fixed: fixed,
        data: entry.value,
        path: path.isEmpty ? entry.key : "$path.${entry.key}",
      );
    }
  }

  @override
  Map<String, dynamic>? toMap<C extends ConfigFields>(
    RemoteConfig<C> remote,
    LocalConfig<C> local,
  ) {
    final remoteMap = remote.maps[this] ?? const {};
    final localMap = local.maps[this] ?? const {};
    final keys = Set.of(localMap.keys)..addAll(remoteMap.keys);
    final map = Map.fromEntries(
      keys.map((k) {
        final remote = remoteMap[k] ?? RemoteConfig<Cfg>.empty(schema);
        final local = localMap[k] ?? LocalConfig<Cfg>();
        return MapEntry(k, local.toMap(remote));
      }).whereType<MapEntry<String, dynamic>>(),
    );
    return map.isEmpty ? null : map;
  }
}

class ProxyObjectField<Cfg extends ConfigFields> extends ConfigField {
  final Cfg schema;

  const ProxyObjectField({required this.schema});

  @override
  void parse({
    required RemoteConfig config,
    required Set<String> fixed,
    required String path,
    required dynamic data,
  }) {
    config.objects[this] = RemoteConfig<Cfg>.fromDataFixed(
      schema,
      fixed: fixed,
      data: data,
      path: path,
    );
    // schema.root.parse(config: config, fixed: fixed, path: path, data: data);
  }

  @override
  Map<String, dynamic>? toMap<C extends ConfigFields>(
    RemoteConfig<C> remote,
    LocalConfig<C> local,
  ) {
    return schema.root.toMap(
      remote.objects[this] ?? RemoteConfig<Cfg>.empty(schema),
      local.objects[this] ?? LocalConfig<Cfg>(),
    );
  }
}
