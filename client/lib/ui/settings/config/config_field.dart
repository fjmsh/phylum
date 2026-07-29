part of 'config.dart';

abstract class ConfigFields {
  ObjectField get root;

  const ConfigFields();
}

sealed class ConfigField {
  const ConfigField();

  dynamic toMap(
    Map<PrimitiveField, RemoteValue> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  );
}

class ObjectField extends ConfigField {
  final Map<String, ConfigField> fields;

  const ObjectField({required this.fields});

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
  final dynamic Function(T)? serialize;
  final T Function(dynamic)? parse;

  PrimitiveField(this.defaultValue, {this.serialize, this.parse});

  RemoteValue<T> ensureType(dynamic value, bool fixed) {
    return RemoteValue._(value: parse?.call(value) ?? value, fixed: fixed);
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
    return serialize?.call(local) ?? local;
  }
}

class MapField<T extends ConfigField> extends ConfigField {
  const MapField();
  @override
  dynamic toMap(
    Map<PrimitiveField, RemoteValue> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  ) => throw UnimplementedError();
}
