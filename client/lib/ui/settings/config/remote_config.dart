import 'package:phylum/ui/settings/config/local_config_updates.dart';

abstract class ConfigFields {
  List<FieldDef> get fields;

  const ConfigFields();
}

class RemoteConfig<C extends ConfigFields> {
  final Map<FieldDef, RemoteValue> values;

  RemoteConfig({required this.values});

  factory RemoteConfig.fromMap(C configDef, Map<String, dynamic> map) {
    final data = (map['config'] as Map).cast<String, dynamic>();
    final fixed = Set.of((map['overrides'] as List).cast<String>());
    final values = <FieldDef, RemoteValue>{};
    for (final field in configDef.fields) {
      values[field] = RemoteValue.create(data, fixed, field);
    }
    return RemoteConfig(values: values);
  }

  T getValue<T>(FieldDef<T> field) {
    return (values[field]?.value as T?) ?? field.defaultValue;
  }

  RemoteConfig<C> apply(LocalConfigUpdates<C> updates) {
    throw UnimplementedError('Not implemented');
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

class RemoteValue<T> {
  final FieldDef<T> field;
  final T value;
  final bool fixed;

  RemoteValue._({
    required this.field,
    required this.value,
    required this.fixed,
  });

  factory RemoteValue.create(
    Map<String, dynamic>? map,
    Set<String> fixed,
    FieldDef<T> field,
  ) {
    String path = field.path;
    while (path.contains(".")) {
      final i = path.indexOf(".");
      map = map?[path.substring(0, i)];
      path = path.substring(i + 1);
    }
    return RemoteValue._(
      field: field,
      value: map?[path] ?? field.defaultValue,
      fixed: fixed.contains(field.path),
    );
  }

  @override
  String toString() {
    return 'RemoteValue (path: ${field.path}, value: $value, fixed: $fixed)';
  }

  @override
  bool operator ==(covariant RemoteValue<T> other) {
    if (identical(this, other)) return true;
    return field == other.field && value == other.value && fixed == other.fixed;
  }

  @override
  int get hashCode => value.hashCode ^ fixed.hashCode;
}
