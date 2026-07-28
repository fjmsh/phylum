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

  const PrimitiveField(this.defaultValue);

  RemoteValue<T> ensureType(dynamic value, bool fixed) {
    return RemoteValue._(value: value, fixed: fixed);
  }

  @override
  dynamic toMap(
    Map<PrimitiveField, RemoteValue> remoteValues,
    Map<PrimitiveField, dynamic> localValues,
  ) {
    if (remoteValues[this]?.fixed == true) return null;
    if (remoteValues[this]?.value == localValues[this]) return null;
    return localValues[this];
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
