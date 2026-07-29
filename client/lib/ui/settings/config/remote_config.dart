part of 'config.dart';

class RemoteConfig<C extends ConfigFields> {
  final C schema;
  final values = <PrimitiveField, RemoteValue>{};

  RemoteConfig._({required this.schema});

  factory RemoteConfig.fromMap(C schema, Map<String, dynamic> map) {
    final data = (map['config'] as Map).cast<String, dynamic>();
    final fixed = Set.of((map['overrides'] as List).cast<String>());
    final config = RemoteConfig._(schema: schema);
    schema.root.parse(config: config, fixed: fixed, path: "", data: data);
    return config;
  }

  T getValue<T>(PrimitiveField<T> field) {
    final remoteValue = values[field];
    final val = (remoteValue?.value as T?) ?? field.defaultValue;
    if (remoteValue?.fixed == false &&
        (val == "" || val == 0 || val == false)) {
      return field.defaultValue;
    }
    return val;
  }

  RemoteConfig<C> apply(LocalConfig<C> updates) {
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
  final T? value;
  final bool fixed;

  RemoteValue._({required this.value, required this.fixed});

  @override
  String toString() {
    return 'RemoteValue (value: $value, fixed: $fixed)';
  }
}
