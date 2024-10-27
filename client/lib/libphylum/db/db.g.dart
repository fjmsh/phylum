// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $ResourcesTable extends Resources
    with TableInfo<$ResourcesTable, Resource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  @override
  late final GeneratedColumn<String> parent = GeneratedColumn<String>(
      'parent', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES resources (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dirMeta = const VerificationMeta('dir');
  @override
  late final GeneratedColumn<bool> dir = GeneratedColumn<bool>(
      'dir', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dir" IN (0, 1))'));
  static const VerificationMeta _modifiedMeta =
      const VerificationMeta('modified');
  @override
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
      'modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
      'sha256', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastFetchMeta =
      const VerificationMeta('lastFetch');
  @override
  late final GeneratedColumn<DateTime> lastFetch = GeneratedColumn<DateTime>(
      'last_fetch', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        parent,
        name,
        dir,
        modified,
        size,
        sha256,
        contentType,
        deleted,
        lastFetch
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resources';
  @override
  VerificationContext validateIntegrity(Insertable<Resource> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent')) {
      context.handle(_parentMeta,
          parent.isAcceptableOrUnknown(data['parent']!, _parentMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dir')) {
      context.handle(
          _dirMeta, dir.isAcceptableOrUnknown(data['dir']!, _dirMeta));
    } else if (isInserting) {
      context.missing(_dirMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(_modifiedMeta,
          modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta));
    } else if (isInserting) {
      context.missing(_modifiedMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(_sha256Meta,
          sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta));
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('last_fetch')) {
      context.handle(_lastFetchMeta,
          lastFetch.isAcceptableOrUnknown(data['last_fetch']!, _lastFetchMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Resource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Resource(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dir: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dir'])!,
      modified: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      sha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      lastFetch: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_fetch']),
    );
  }

  @override
  $ResourcesTable createAlias(String alias) {
    return $ResourcesTable(attachedDatabase, alias);
  }
}

class Resource extends DataClass implements Insertable<Resource> {
  final String id;
  final String? parent;
  final String name;
  final bool dir;
  final DateTime modified;
  final int size;
  final String sha256;
  final String contentType;
  final bool deleted;
  final DateTime? lastFetch;
  const Resource(
      {required this.id,
      this.parent,
      required this.name,
      required this.dir,
      required this.modified,
      required this.size,
      required this.sha256,
      required this.contentType,
      required this.deleted,
      this.lastFetch});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parent != null) {
      map['parent'] = Variable<String>(parent);
    }
    map['name'] = Variable<String>(name);
    map['dir'] = Variable<bool>(dir);
    map['modified'] = Variable<DateTime>(modified);
    map['size'] = Variable<int>(size);
    map['sha256'] = Variable<String>(sha256);
    map['content_type'] = Variable<String>(contentType);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || lastFetch != null) {
      map['last_fetch'] = Variable<DateTime>(lastFetch);
    }
    return map;
  }

  ResourcesCompanion toCompanion(bool nullToAbsent) {
    return ResourcesCompanion(
      id: Value(id),
      parent:
          parent == null && nullToAbsent ? const Value.absent() : Value(parent),
      name: Value(name),
      dir: Value(dir),
      modified: Value(modified),
      size: Value(size),
      sha256: Value(sha256),
      contentType: Value(contentType),
      deleted: Value(deleted),
      lastFetch: lastFetch == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetch),
    );
  }

  factory Resource.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Resource(
      id: serializer.fromJson<String>(json['id']),
      parent: serializer.fromJson<String?>(json['parent']),
      name: serializer.fromJson<String>(json['name']),
      dir: serializer.fromJson<bool>(json['dir']),
      modified: serializer.fromJson<DateTime>(json['modified']),
      size: serializer.fromJson<int>(json['size']),
      sha256: serializer.fromJson<String>(json['sha256']),
      contentType: serializer.fromJson<String>(json['contentType']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      lastFetch: serializer.fromJson<DateTime?>(json['lastFetch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parent': serializer.toJson<String?>(parent),
      'name': serializer.toJson<String>(name),
      'dir': serializer.toJson<bool>(dir),
      'modified': serializer.toJson<DateTime>(modified),
      'size': serializer.toJson<int>(size),
      'sha256': serializer.toJson<String>(sha256),
      'contentType': serializer.toJson<String>(contentType),
      'deleted': serializer.toJson<bool>(deleted),
      'lastFetch': serializer.toJson<DateTime?>(lastFetch),
    };
  }

  Resource copyWith(
          {String? id,
          Value<String?> parent = const Value.absent(),
          String? name,
          bool? dir,
          DateTime? modified,
          int? size,
          String? sha256,
          String? contentType,
          bool? deleted,
          Value<DateTime?> lastFetch = const Value.absent()}) =>
      Resource(
        id: id ?? this.id,
        parent: parent.present ? parent.value : this.parent,
        name: name ?? this.name,
        dir: dir ?? this.dir,
        modified: modified ?? this.modified,
        size: size ?? this.size,
        sha256: sha256 ?? this.sha256,
        contentType: contentType ?? this.contentType,
        deleted: deleted ?? this.deleted,
        lastFetch: lastFetch.present ? lastFetch.value : this.lastFetch,
      );
  Resource copyWithCompanion(ResourcesCompanion data) {
    return Resource(
      id: data.id.present ? data.id.value : this.id,
      parent: data.parent.present ? data.parent.value : this.parent,
      name: data.name.present ? data.name.value : this.name,
      dir: data.dir.present ? data.dir.value : this.dir,
      modified: data.modified.present ? data.modified.value : this.modified,
      size: data.size.present ? data.size.value : this.size,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      lastFetch: data.lastFetch.present ? data.lastFetch.value : this.lastFetch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Resource(')
          ..write('id: $id, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('dir: $dir, ')
          ..write('modified: $modified, ')
          ..write('size: $size, ')
          ..write('sha256: $sha256, ')
          ..write('contentType: $contentType, ')
          ..write('deleted: $deleted, ')
          ..write('lastFetch: $lastFetch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parent, name, dir, modified, size, sha256,
      contentType, deleted, lastFetch);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Resource &&
          other.id == this.id &&
          other.parent == this.parent &&
          other.name == this.name &&
          other.dir == this.dir &&
          other.modified == this.modified &&
          other.size == this.size &&
          other.sha256 == this.sha256 &&
          other.contentType == this.contentType &&
          other.deleted == this.deleted &&
          other.lastFetch == this.lastFetch);
}

class ResourcesCompanion extends UpdateCompanion<Resource> {
  final Value<String> id;
  final Value<String?> parent;
  final Value<String> name;
  final Value<bool> dir;
  final Value<DateTime> modified;
  final Value<int> size;
  final Value<String> sha256;
  final Value<String> contentType;
  final Value<bool> deleted;
  final Value<DateTime?> lastFetch;
  final Value<int> rowid;
  const ResourcesCompanion({
    this.id = const Value.absent(),
    this.parent = const Value.absent(),
    this.name = const Value.absent(),
    this.dir = const Value.absent(),
    this.modified = const Value.absent(),
    this.size = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.contentType = const Value.absent(),
    this.deleted = const Value.absent(),
    this.lastFetch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResourcesCompanion.insert({
    required String id,
    this.parent = const Value.absent(),
    required String name,
    required bool dir,
    required DateTime modified,
    required int size,
    required String sha256,
    required String contentType,
    this.deleted = const Value.absent(),
    this.lastFetch = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        dir = Value(dir),
        modified = Value(modified),
        size = Value(size),
        sha256 = Value(sha256),
        contentType = Value(contentType);
  static Insertable<Resource> custom({
    Expression<String>? id,
    Expression<String>? parent,
    Expression<String>? name,
    Expression<bool>? dir,
    Expression<DateTime>? modified,
    Expression<int>? size,
    Expression<String>? sha256,
    Expression<String>? contentType,
    Expression<bool>? deleted,
    Expression<DateTime>? lastFetch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parent != null) 'parent': parent,
      if (name != null) 'name': name,
      if (dir != null) 'dir': dir,
      if (modified != null) 'modified': modified,
      if (size != null) 'size': size,
      if (sha256 != null) 'sha256': sha256,
      if (contentType != null) 'content_type': contentType,
      if (deleted != null) 'deleted': deleted,
      if (lastFetch != null) 'last_fetch': lastFetch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResourcesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parent,
      Value<String>? name,
      Value<bool>? dir,
      Value<DateTime>? modified,
      Value<int>? size,
      Value<String>? sha256,
      Value<String>? contentType,
      Value<bool>? deleted,
      Value<DateTime?>? lastFetch,
      Value<int>? rowid}) {
    return ResourcesCompanion(
      id: id ?? this.id,
      parent: parent ?? this.parent,
      name: name ?? this.name,
      dir: dir ?? this.dir,
      modified: modified ?? this.modified,
      size: size ?? this.size,
      sha256: sha256 ?? this.sha256,
      contentType: contentType ?? this.contentType,
      deleted: deleted ?? this.deleted,
      lastFetch: lastFetch ?? this.lastFetch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parent.present) {
      map['parent'] = Variable<String>(parent.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dir.present) {
      map['dir'] = Variable<bool>(dir.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (lastFetch.present) {
      map['last_fetch'] = Variable<DateTime>(lastFetch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResourcesCompanion(')
          ..write('id: $id, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('dir: $dir, ')
          ..write('modified: $modified, ')
          ..write('size: $size, ')
          ..write('sha256: $sha256, ')
          ..write('contentType: $contentType, ')
          ..write('deleted: $deleted, ')
          ..write('lastFetch: $lastFetch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ResourcesTable resources = $ResourcesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [resources];
}

typedef $$ResourcesTableCreateCompanionBuilder = ResourcesCompanion Function({
  required String id,
  Value<String?> parent,
  required String name,
  required bool dir,
  required DateTime modified,
  required int size,
  required String sha256,
  required String contentType,
  Value<bool> deleted,
  Value<DateTime?> lastFetch,
  Value<int> rowid,
});
typedef $$ResourcesTableUpdateCompanionBuilder = ResourcesCompanion Function({
  Value<String> id,
  Value<String?> parent,
  Value<String> name,
  Value<bool> dir,
  Value<DateTime> modified,
  Value<int> size,
  Value<String> sha256,
  Value<String> contentType,
  Value<bool> deleted,
  Value<DateTime?> lastFetch,
  Value<int> rowid,
});

final class $$ResourcesTableReferences
    extends BaseReferences<_$AppDatabase, $ResourcesTable, Resource> {
  $$ResourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ResourcesTable _parentTable(_$AppDatabase db) => db.resources
      .createAlias($_aliasNameGenerator(db.resources.parent, db.resources.id));

  $$ResourcesTableProcessedTableManager? get parent {
    if ($_item.parent == null) return null;
    final manager = $$ResourcesTableTableManager($_db, $_db.resources)
        .filter((f) => f.id($_item.parent!));
    final item = $_typedResult.readTableOrNull(_parentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ResourcesTableFilterComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dir => $composableBuilder(
      column: $table.dir, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modified => $composableBuilder(
      column: $table.modified, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFetch => $composableBuilder(
      column: $table.lastFetch, builder: (column) => ColumnFilters(column));

  $$ResourcesTableFilterComposer get parent {
    final $$ResourcesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parent,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ResourcesTableFilterComposer(
              $db: $db,
              $table: $db.resources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ResourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dir => $composableBuilder(
      column: $table.dir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modified => $composableBuilder(
      column: $table.modified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFetch => $composableBuilder(
      column: $table.lastFetch, builder: (column) => ColumnOrderings(column));

  $$ResourcesTableOrderingComposer get parent {
    final $$ResourcesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parent,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ResourcesTableOrderingComposer(
              $db: $db,
              $table: $db.resources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ResourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResourcesTable> {
  $$ResourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get dir =>
      $composableBuilder(column: $table.dir, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetch =>
      $composableBuilder(column: $table.lastFetch, builder: (column) => column);

  $$ResourcesTableAnnotationComposer get parent {
    final $$ResourcesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parent,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ResourcesTableAnnotationComposer(
              $db: $db,
              $table: $db.resources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ResourcesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ResourcesTable,
    Resource,
    $$ResourcesTableFilterComposer,
    $$ResourcesTableOrderingComposer,
    $$ResourcesTableAnnotationComposer,
    $$ResourcesTableCreateCompanionBuilder,
    $$ResourcesTableUpdateCompanionBuilder,
    (Resource, $$ResourcesTableReferences),
    Resource,
    PrefetchHooks Function({bool parent})> {
  $$ResourcesTableTableManager(_$AppDatabase db, $ResourcesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parent = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> dir = const Value.absent(),
            Value<DateTime> modified = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<String> sha256 = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<DateTime?> lastFetch = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResourcesCompanion(
            id: id,
            parent: parent,
            name: name,
            dir: dir,
            modified: modified,
            size: size,
            sha256: sha256,
            contentType: contentType,
            deleted: deleted,
            lastFetch: lastFetch,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parent = const Value.absent(),
            required String name,
            required bool dir,
            required DateTime modified,
            required int size,
            required String sha256,
            required String contentType,
            Value<bool> deleted = const Value.absent(),
            Value<DateTime?> lastFetch = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResourcesCompanion.insert(
            id: id,
            parent: parent,
            name: name,
            dir: dir,
            modified: modified,
            size: size,
            sha256: sha256,
            contentType: contentType,
            deleted: deleted,
            lastFetch: lastFetch,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ResourcesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({parent = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (parent) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parent,
                    referencedTable:
                        $$ResourcesTableReferences._parentTable(db),
                    referencedColumn:
                        $$ResourcesTableReferences._parentTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ResourcesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ResourcesTable,
    Resource,
    $$ResourcesTableFilterComposer,
    $$ResourcesTableOrderingComposer,
    $$ResourcesTableAnnotationComposer,
    $$ResourcesTableCreateCompanionBuilder,
    $$ResourcesTableUpdateCompanionBuilder,
    (Resource, $$ResourcesTableReferences),
    Resource,
    PrefetchHooks Function({bool parent})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ResourcesTableTableManager get resources =>
      $$ResourcesTableTableManager(_db, _db.resources);
}
