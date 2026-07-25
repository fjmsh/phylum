class RemoteConfig {
  final Map<FieldDef, RemoteValue?> values;

  RemoteConfig({required this.values});

  factory RemoteConfig.fromMap(
    Map<String, dynamic> map,
    Set<String> fixed,
    List<FieldDef> fields,
  ) {
    final values = <FieldDef, RemoteValue?>{};
    for (final field in fields) {
      values[field] = RemoteValue.create(map, fixed, field);
      print('Parsed ${field.path}: ${values[field]}');
    }
    return RemoteConfig(values: values);
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    for (final entry in values.entries) {
      String path = entry.key.path;
      Map<String, dynamic> map = result;
      while (path.contains(".")) {
        final i = path.indexOf(".");
        final key = path.substring(0, i);
        if (map[key] == null) {
          final m = <String, dynamic>{};
          map[key] = m;
          map = m;
        } else if (map[key] is Map<String, dynamic>) {
          map = map[key];
        } else {}
        path = path.substring(i + 1);
      }
      map[path] = entry.value?.value;
    }
    return result;
  }
}

class FieldDef<T> {
  final String path;
  final T defaultValue;

  const FieldDef({required this.path, required this.defaultValue});
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
