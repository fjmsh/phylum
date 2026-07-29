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
    Map<PrimitiveField, RemoteValue> remoteValues,
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
    Map<PrimitiveField, RemoteValue> remoteValues,
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
    config.values[this] = RemoteValue._(
      value: fromPrimitive?.call(data) ?? data,
      fixed: fixed.contains(path),
    );
  }

  @override
  dynamic toMap(
    Map<PrimitiveField, RemoteValue> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  ) {
    final remote = remoteValues[this];
    final local = localValues[this];
    if (remote?.fixed == true) return null;
    if (remote?.value == local) return null;
    return toPrimitive?.call(local) ?? local;
  }
}

class MapField<T extends ConfigField> extends ConfigField {
  const MapField();

  @override
  void parse({
    required RemoteConfig config,
    required Set<String> fixed,
    required String path,
    required dynamic data,
  }) => throw UnimplementedError();

  @override
  dynamic toMap(
    Map<PrimitiveField, RemoteValue> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  ) => throw UnimplementedError();
}
