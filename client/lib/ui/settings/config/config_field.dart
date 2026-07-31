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

  dynamic toMap(
    Map<PrimitiveField, dynamic> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
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
  Map<String, dynamic>? toMap(
    Map<PrimitiveField, dynamic> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  ) {
    final map = Map.fromEntries(
      fields.entries
          .map((e) {
            final sub = e.value.toMap(remoteValues, localValues);
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
  dynamic toMap(
    Map<PrimitiveField, dynamic> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  ) {
    final remote = remoteValues[this];
    final local = localValues[this];
    if (local == null || local == remote) return null;
    return toPrimitive?.call(local) ?? local;
  }
}

class MapField<C extends ConfigFields> extends ConfigField {
  final C schema;

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
      )[entry.key] = RemoteConfig<C>.fromDataFixed(
        schema,
        entry.value,
        fixed,
        path.isEmpty ? entry.key : "$path.${entry.key}",
      );
    }
  }

  @override
  dynamic toMap(
    Map<PrimitiveField, dynamic> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  ) => throw UnimplementedError();
}
