import 'package:phylum/ui/settings/config/local_config.dart';

class RemoteConfig<C extends ConfigFields> {
  final C schema;
  final Map<PrimitiveField, RemoteValue> values;

  RemoteConfig({required this.schema, required this.values});

  factory RemoteConfig.fromMap(C schema, Map<String, dynamic> map) {
    final data = (map['config'] as Map).cast<String, dynamic>();
    final fixed = Set.of((map['overrides'] as List).cast<String>());
    final values = <PrimitiveField, RemoteValue>{};
    parseObject(values, fixed, "", schema.root, data);
    return RemoteConfig(schema: schema, values: values);
  }

  static void parseObject(
    Map<PrimitiveField, RemoteValue> values,
    Set<String> fixed,
    String path,
    ObjectField field,
    dynamic data,
  ) {
    data = (data as Map).cast<String, dynamic>();
    for (final entry in field.fields.entries) {
      if (!data.containsKey(entry.key)) continue;
      final fieldPath = path.isEmpty ? entry.key : "$path.${entry.key}";
      final field = entry.value;
      final fieldData = data[entry.key];
      switch (field) {
        case ObjectField():
          parseObject(values, fixed, fieldPath, field, fieldData);
          break;
        case PrimitiveField():
          values[field] = field.ensureType(
            fieldData,
            fixed.contains(fieldPath),
          );
          break;
        case MapField<ConfigField>():
          throw UnimplementedError();
      }
    }
  }

  T getValue<T>(PrimitiveField<T> field) {
    return (values[field]?.value as T?) ?? field.defaultValue;
  }

  RemoteConfig<C> apply(LocalConfig<C> updates) {
    throw UnimplementedError('Not implemented');
  }
}

abstract class ConfigFields {
  ObjectField get root;

  const ConfigFields();
}

sealed class ConfigField {
  const ConfigField();
}

class ObjectField extends ConfigField {
  final Map<String, ConfigField> fields;

  const ObjectField({required this.fields});
}

class PrimitiveField<T> extends ConfigField {
  final T defaultValue;

  const PrimitiveField(this.defaultValue);

  RemoteValue<T> ensureType(dynamic value, bool fixed) {
    return RemoteValue._(value: value ?? defaultValue, fixed: fixed);
  }
}

class MapField<T extends ConfigField> extends ConfigField {
  const MapField();
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

class RemoteValue<T> {
  final T value;
  final bool fixed;

  RemoteValue._({required this.value, required this.fixed});

  @override
  String toString() {
    return 'RemoteValue (value: $value, fixed: $fixed)';
  }
}
