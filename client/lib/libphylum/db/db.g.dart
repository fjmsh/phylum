// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class Users extends Table with TableInfo<Users, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  static const VerificationMeta _displayMeta =
      const VerificationMeta('display');
  late final GeneratedColumn<String> display = GeneratedColumn<String>(
      'display', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [username, display];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display')) {
      context.handle(_displayMeta,
          display.isAcceptableOrUnknown(data['display']!, _displayMeta));
    } else if (isInserting) {
      context.missing(_displayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {username};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      display: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display'])!,
    );
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class User extends DataClass implements Insertable<User> {
  final String username;
  final String display;
  const User({required this.username, required this.display});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['username'] = Variable<String>(username);
    map['display'] = Variable<String>(display);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      username: Value(username),
      display: Value(display),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      username: serializer.fromJson<String>(json['username']),
      display: serializer.fromJson<String>(json['display']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'username': serializer.toJson<String>(username),
      'display': serializer.toJson<String>(display),
    };
  }

  User copyWith({String? username, String? display}) => User(
        username: username ?? this.username,
        display: display ?? this.display,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      username: data.username.present ? data.username.value : this.username,
      display: data.display.present ? data.display.value : this.display,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('username: $username, ')
          ..write('display: $display')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(username, display);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.username == this.username &&
          other.display == this.display);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> username;
  final Value<String> display;
  final Value<int> rowid;
  const UsersCompanion({
    this.username = const Value.absent(),
    this.display = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String username,
    required String display,
    this.rowid = const Value.absent(),
  })  : username = Value(username),
        display = Value(display);
  static Insertable<User> custom({
    Expression<String>? username,
    Expression<String>? display,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (username != null) 'username': username,
      if (display != null) 'display': display,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? username, Value<String>? display, Value<int>? rowid}) {
    return UsersCompanion(
      username: username ?? this.username,
      display: display ?? this.display,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (display.present) {
      map['display'] = Variable<String>(display.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('username: $username, ')
          ..write('display: $display, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Resources extends Table with TableInfo<Resources, Resource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Resources(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  late final GeneratedColumn<String> parent = GeneratedColumn<String>(
      'parent', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES resources(id)');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _dirMeta = const VerificationMeta('dir');
  late final GeneratedColumn<bool> dir = GeneratedColumn<bool>(
      'dir', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (dir IN (0, 1))');
  static const VerificationMeta _createdMeta =
      const VerificationMeta('created');
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
      'created', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _modifiedMeta =
      const VerificationMeta('modified');
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
      'modified', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0 CHECK (deleted IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _contentSizeMeta =
      const VerificationMeta('contentSize');
  late final GeneratedColumn<int> contentSize = GeneratedColumn<int>(
      'content_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _contentSha256Meta =
      const VerificationMeta('contentSha256');
  late final GeneratedColumn<String> contentSha256 = GeneratedColumn<String>(
      'content_sha256', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT \'\'',
      defaultValue: const CustomExpression('\'\''));
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT \'\'',
      defaultValue: const CustomExpression('\'\''));
  static const VerificationMeta _permissionsMeta =
      const VerificationMeta('permissions');
  late final GeneratedColumn<String> permissions = GeneratedColumn<String>(
      'permissions', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
  static const VerificationMeta _publinksMeta =
      const VerificationMeta('publinks');
  late final GeneratedColumn<int> publinks = GeneratedColumn<int>(
      'publinks', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  static const VerificationMeta _lastRefreshMeta =
      const VerificationMeta('lastRefresh');
  late final GeneratedColumn<DateTime> lastRefresh = GeneratedColumn<DateTime>(
      'last_refresh', aliasedName, true,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      $customConstraints: '');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        parent,
        name,
        dir,
        created,
        modified,
        deleted,
        contentSize,
        contentSha256,
        contentType,
        permissions,
        publinks,
        lastRefresh
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
    if (data.containsKey('created')) {
      context.handle(_createdMeta,
          created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    }
    if (data.containsKey('modified')) {
      context.handle(_modifiedMeta,
          modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('content_size')) {
      context.handle(
          _contentSizeMeta,
          contentSize.isAcceptableOrUnknown(
              data['content_size']!, _contentSizeMeta));
    }
    if (data.containsKey('content_sha256')) {
      context.handle(
          _contentSha256Meta,
          contentSha256.isAcceptableOrUnknown(
              data['content_sha256']!, _contentSha256Meta));
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    }
    if (data.containsKey('permissions')) {
      context.handle(
          _permissionsMeta,
          permissions.isAcceptableOrUnknown(
              data['permissions']!, _permissionsMeta));
    }
    if (data.containsKey('publinks')) {
      context.handle(_publinksMeta,
          publinks.isAcceptableOrUnknown(data['publinks']!, _publinksMeta));
    }
    if (data.containsKey('last_refresh')) {
      context.handle(
          _lastRefreshMeta,
          lastRefresh.isAcceptableOrUnknown(
              data['last_refresh']!, _lastRefreshMeta));
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
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created']),
      modified: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified']),
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      contentSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}content_size'])!,
      contentSha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_sha256'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      permissions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}permissions']),
      publinks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}publinks'])!,
      lastRefresh: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_refresh']),
    );
  }

  @override
  Resources createAlias(String alias) {
    return Resources(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Resource extends DataClass implements Insertable<Resource> {
  final String id;
  final String? parent;
  final String name;
  final bool dir;
  final DateTime? created;
  final DateTime? modified;
  final bool deleted;
  final int contentSize;
  final String contentSha256;
  final String contentType;
  final String? permissions;
  final int publinks;
  final DateTime? lastRefresh;
  const Resource(
      {required this.id,
      this.parent,
      required this.name,
      required this.dir,
      this.created,
      this.modified,
      required this.deleted,
      required this.contentSize,
      required this.contentSha256,
      required this.contentType,
      this.permissions,
      required this.publinks,
      this.lastRefresh});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parent != null) {
      map['parent'] = Variable<String>(parent);
    }
    map['name'] = Variable<String>(name);
    map['dir'] = Variable<bool>(dir);
    if (!nullToAbsent || created != null) {
      map['created'] = Variable<DateTime>(created);
    }
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<DateTime>(modified);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['content_size'] = Variable<int>(contentSize);
    map['content_sha256'] = Variable<String>(contentSha256);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || permissions != null) {
      map['permissions'] = Variable<String>(permissions);
    }
    map['publinks'] = Variable<int>(publinks);
    if (!nullToAbsent || lastRefresh != null) {
      map['last_refresh'] = Variable<DateTime>(lastRefresh);
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
      created: created == null && nullToAbsent
          ? const Value.absent()
          : Value(created),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      deleted: Value(deleted),
      contentSize: Value(contentSize),
      contentSha256: Value(contentSha256),
      contentType: Value(contentType),
      permissions: permissions == null && nullToAbsent
          ? const Value.absent()
          : Value(permissions),
      publinks: Value(publinks),
      lastRefresh: lastRefresh == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefresh),
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
      created: serializer.fromJson<DateTime?>(json['created']),
      modified: serializer.fromJson<DateTime?>(json['modified']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      contentSize: serializer.fromJson<int>(json['content_size']),
      contentSha256: serializer.fromJson<String>(json['content_sha256']),
      contentType: serializer.fromJson<String>(json['content_type']),
      permissions: serializer.fromJson<String?>(json['permissions']),
      publinks: serializer.fromJson<int>(json['publinks']),
      lastRefresh: serializer.fromJson<DateTime?>(json['last_refresh']),
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
      'created': serializer.toJson<DateTime?>(created),
      'modified': serializer.toJson<DateTime?>(modified),
      'deleted': serializer.toJson<bool>(deleted),
      'content_size': serializer.toJson<int>(contentSize),
      'content_sha256': serializer.toJson<String>(contentSha256),
      'content_type': serializer.toJson<String>(contentType),
      'permissions': serializer.toJson<String?>(permissions),
      'publinks': serializer.toJson<int>(publinks),
      'last_refresh': serializer.toJson<DateTime?>(lastRefresh),
    };
  }

  Resource copyWith(
          {String? id,
          Value<String?> parent = const Value.absent(),
          String? name,
          bool? dir,
          Value<DateTime?> created = const Value.absent(),
          Value<DateTime?> modified = const Value.absent(),
          bool? deleted,
          int? contentSize,
          String? contentSha256,
          String? contentType,
          Value<String?> permissions = const Value.absent(),
          int? publinks,
          Value<DateTime?> lastRefresh = const Value.absent()}) =>
      Resource(
        id: id ?? this.id,
        parent: parent.present ? parent.value : this.parent,
        name: name ?? this.name,
        dir: dir ?? this.dir,
        created: created.present ? created.value : this.created,
        modified: modified.present ? modified.value : this.modified,
        deleted: deleted ?? this.deleted,
        contentSize: contentSize ?? this.contentSize,
        contentSha256: contentSha256 ?? this.contentSha256,
        contentType: contentType ?? this.contentType,
        permissions: permissions.present ? permissions.value : this.permissions,
        publinks: publinks ?? this.publinks,
        lastRefresh: lastRefresh.present ? lastRefresh.value : this.lastRefresh,
      );
  Resource copyWithCompanion(ResourcesCompanion data) {
    return Resource(
      id: data.id.present ? data.id.value : this.id,
      parent: data.parent.present ? data.parent.value : this.parent,
      name: data.name.present ? data.name.value : this.name,
      dir: data.dir.present ? data.dir.value : this.dir,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      contentSize:
          data.contentSize.present ? data.contentSize.value : this.contentSize,
      contentSha256: data.contentSha256.present
          ? data.contentSha256.value
          : this.contentSha256,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      permissions:
          data.permissions.present ? data.permissions.value : this.permissions,
      publinks: data.publinks.present ? data.publinks.value : this.publinks,
      lastRefresh:
          data.lastRefresh.present ? data.lastRefresh.value : this.lastRefresh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Resource(')
          ..write('id: $id, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('dir: $dir, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('deleted: $deleted, ')
          ..write('contentSize: $contentSize, ')
          ..write('contentSha256: $contentSha256, ')
          ..write('contentType: $contentType, ')
          ..write('permissions: $permissions, ')
          ..write('publinks: $publinks, ')
          ..write('lastRefresh: $lastRefresh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      parent,
      name,
      dir,
      created,
      modified,
      deleted,
      contentSize,
      contentSha256,
      contentType,
      permissions,
      publinks,
      lastRefresh);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Resource &&
          other.id == this.id &&
          other.parent == this.parent &&
          other.name == this.name &&
          other.dir == this.dir &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.deleted == this.deleted &&
          other.contentSize == this.contentSize &&
          other.contentSha256 == this.contentSha256 &&
          other.contentType == this.contentType &&
          other.permissions == this.permissions &&
          other.publinks == this.publinks &&
          other.lastRefresh == this.lastRefresh);
}

class ResourcesCompanion extends UpdateCompanion<Resource> {
  final Value<String> id;
  final Value<String?> parent;
  final Value<String> name;
  final Value<bool> dir;
  final Value<DateTime?> created;
  final Value<DateTime?> modified;
  final Value<bool> deleted;
  final Value<int> contentSize;
  final Value<String> contentSha256;
  final Value<String> contentType;
  final Value<String?> permissions;
  final Value<int> publinks;
  final Value<DateTime?> lastRefresh;
  final Value<int> rowid;
  const ResourcesCompanion({
    this.id = const Value.absent(),
    this.parent = const Value.absent(),
    this.name = const Value.absent(),
    this.dir = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.deleted = const Value.absent(),
    this.contentSize = const Value.absent(),
    this.contentSha256 = const Value.absent(),
    this.contentType = const Value.absent(),
    this.permissions = const Value.absent(),
    this.publinks = const Value.absent(),
    this.lastRefresh = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResourcesCompanion.insert({
    required String id,
    this.parent = const Value.absent(),
    required String name,
    required bool dir,
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.deleted = const Value.absent(),
    this.contentSize = const Value.absent(),
    this.contentSha256 = const Value.absent(),
    this.contentType = const Value.absent(),
    this.permissions = const Value.absent(),
    this.publinks = const Value.absent(),
    this.lastRefresh = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        dir = Value(dir);
  static Insertable<Resource> custom({
    Expression<String>? id,
    Expression<String>? parent,
    Expression<String>? name,
    Expression<bool>? dir,
    Expression<DateTime>? created,
    Expression<DateTime>? modified,
    Expression<bool>? deleted,
    Expression<int>? contentSize,
    Expression<String>? contentSha256,
    Expression<String>? contentType,
    Expression<String>? permissions,
    Expression<int>? publinks,
    Expression<DateTime>? lastRefresh,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parent != null) 'parent': parent,
      if (name != null) 'name': name,
      if (dir != null) 'dir': dir,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (deleted != null) 'deleted': deleted,
      if (contentSize != null) 'content_size': contentSize,
      if (contentSha256 != null) 'content_sha256': contentSha256,
      if (contentType != null) 'content_type': contentType,
      if (permissions != null) 'permissions': permissions,
      if (publinks != null) 'publinks': publinks,
      if (lastRefresh != null) 'last_refresh': lastRefresh,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResourcesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parent,
      Value<String>? name,
      Value<bool>? dir,
      Value<DateTime?>? created,
      Value<DateTime?>? modified,
      Value<bool>? deleted,
      Value<int>? contentSize,
      Value<String>? contentSha256,
      Value<String>? contentType,
      Value<String?>? permissions,
      Value<int>? publinks,
      Value<DateTime?>? lastRefresh,
      Value<int>? rowid}) {
    return ResourcesCompanion(
      id: id ?? this.id,
      parent: parent ?? this.parent,
      name: name ?? this.name,
      dir: dir ?? this.dir,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      deleted: deleted ?? this.deleted,
      contentSize: contentSize ?? this.contentSize,
      contentSha256: contentSha256 ?? this.contentSha256,
      contentType: contentType ?? this.contentType,
      permissions: permissions ?? this.permissions,
      publinks: publinks ?? this.publinks,
      lastRefresh: lastRefresh ?? this.lastRefresh,
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
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (contentSize.present) {
      map['content_size'] = Variable<int>(contentSize.value);
    }
    if (contentSha256.present) {
      map['content_sha256'] = Variable<String>(contentSha256.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(permissions.value);
    }
    if (publinks.present) {
      map['publinks'] = Variable<int>(publinks.value);
    }
    if (lastRefresh.present) {
      map['last_refresh'] = Variable<DateTime>(lastRefresh.value);
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
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('deleted: $deleted, ')
          ..write('contentSize: $contentSize, ')
          ..write('contentSha256: $contentSha256, ')
          ..write('contentType: $contentType, ')
          ..write('permissions: $permissions, ')
          ..write('publinks: $publinks, ')
          ..write('lastRefresh: $lastRefresh, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Users users = Users(this);
  late final Resources resources = Resources(this);
  Selectable<ParentsResult> parents(String id) {
    return customSelect(
        'WITH RECURSIVE parents (id, parent, name, permissions) AS (SELECT id, parent, name, permissions FROM resources WHERE id = ?1 UNION ALL SELECT r.id, r.parent, r.name, r.permissions FROM resources AS r JOIN parents AS p ON r.id = p.parent) SELECT * FROM parents',
        variables: [
          Variable<String>(id)
        ],
        readsFrom: {
          resources,
        }).map((QueryRow row) => ParentsResult(
          id: row.read<String>('id'),
          parent: row.readNullable<String>('parent'),
          name: row.read<String>('name'),
          permissions: row.readNullable<String>('permissions'),
        ));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, resources];
}

typedef $UsersCreateCompanionBuilder = UsersCompanion Function({
  required String username,
  required String display,
  Value<int> rowid,
});
typedef $UsersUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> username,
  Value<String> display,
  Value<int> rowid,
});

class $UsersFilterComposer extends Composer<_$AppDatabase, Users> {
  $UsersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get display => $composableBuilder(
      column: $table.display, builder: (column) => ColumnFilters(column));
}

class $UsersOrderingComposer extends Composer<_$AppDatabase, Users> {
  $UsersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get display => $composableBuilder(
      column: $table.display, builder: (column) => ColumnOrderings(column));
}

class $UsersAnnotationComposer extends Composer<_$AppDatabase, Users> {
  $UsersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get display =>
      $composableBuilder(column: $table.display, builder: (column) => column);
}

class $UsersTableManager extends RootTableManager<
    _$AppDatabase,
    Users,
    User,
    $UsersFilterComposer,
    $UsersOrderingComposer,
    $UsersAnnotationComposer,
    $UsersCreateCompanionBuilder,
    $UsersUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, Users, User>),
    User,
    PrefetchHooks Function()> {
  $UsersTableManager(_$AppDatabase db, Users table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $UsersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $UsersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $UsersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> username = const Value.absent(),
            Value<String> display = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            username: username,
            display: display,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String username,
            required String display,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            username: username,
            display: display,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $UsersProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Users,
    User,
    $UsersFilterComposer,
    $UsersOrderingComposer,
    $UsersAnnotationComposer,
    $UsersCreateCompanionBuilder,
    $UsersUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, Users, User>),
    User,
    PrefetchHooks Function()>;
typedef $ResourcesCreateCompanionBuilder = ResourcesCompanion Function({
  required String id,
  Value<String?> parent,
  required String name,
  required bool dir,
  Value<DateTime?> created,
  Value<DateTime?> modified,
  Value<bool> deleted,
  Value<int> contentSize,
  Value<String> contentSha256,
  Value<String> contentType,
  Value<String?> permissions,
  Value<int> publinks,
  Value<DateTime?> lastRefresh,
  Value<int> rowid,
});
typedef $ResourcesUpdateCompanionBuilder = ResourcesCompanion Function({
  Value<String> id,
  Value<String?> parent,
  Value<String> name,
  Value<bool> dir,
  Value<DateTime?> created,
  Value<DateTime?> modified,
  Value<bool> deleted,
  Value<int> contentSize,
  Value<String> contentSha256,
  Value<String> contentType,
  Value<String?> permissions,
  Value<int> publinks,
  Value<DateTime?> lastRefresh,
  Value<int> rowid,
});

class $ResourcesFilterComposer extends Composer<_$AppDatabase, Resources> {
  $ResourcesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parent => $composableBuilder(
      column: $table.parent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dir => $composableBuilder(
      column: $table.dir, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modified => $composableBuilder(
      column: $table.modified, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get contentSize => $composableBuilder(
      column: $table.contentSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentSha256 => $composableBuilder(
      column: $table.contentSha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get publinks => $composableBuilder(
      column: $table.publinks, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastRefresh => $composableBuilder(
      column: $table.lastRefresh, builder: (column) => ColumnFilters(column));
}

class $ResourcesOrderingComposer extends Composer<_$AppDatabase, Resources> {
  $ResourcesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parent => $composableBuilder(
      column: $table.parent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dir => $composableBuilder(
      column: $table.dir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modified => $composableBuilder(
      column: $table.modified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get contentSize => $composableBuilder(
      column: $table.contentSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentSha256 => $composableBuilder(
      column: $table.contentSha256,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get publinks => $composableBuilder(
      column: $table.publinks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastRefresh => $composableBuilder(
      column: $table.lastRefresh, builder: (column) => ColumnOrderings(column));
}

class $ResourcesAnnotationComposer extends Composer<_$AppDatabase, Resources> {
  $ResourcesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parent =>
      $composableBuilder(column: $table.parent, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get dir =>
      $composableBuilder(column: $table.dir, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get contentSize => $composableBuilder(
      column: $table.contentSize, builder: (column) => column);

  GeneratedColumn<String> get contentSha256 => $composableBuilder(
      column: $table.contentSha256, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => column);

  GeneratedColumn<int> get publinks =>
      $composableBuilder(column: $table.publinks, builder: (column) => column);

  GeneratedColumn<DateTime> get lastRefresh => $composableBuilder(
      column: $table.lastRefresh, builder: (column) => column);
}

class $ResourcesTableManager extends RootTableManager<
    _$AppDatabase,
    Resources,
    Resource,
    $ResourcesFilterComposer,
    $ResourcesOrderingComposer,
    $ResourcesAnnotationComposer,
    $ResourcesCreateCompanionBuilder,
    $ResourcesUpdateCompanionBuilder,
    (Resource, BaseReferences<_$AppDatabase, Resources, Resource>),
    Resource,
    PrefetchHooks Function()> {
  $ResourcesTableManager(_$AppDatabase db, Resources table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ResourcesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ResourcesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ResourcesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parent = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> dir = const Value.absent(),
            Value<DateTime?> created = const Value.absent(),
            Value<DateTime?> modified = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> contentSize = const Value.absent(),
            Value<String> contentSha256 = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> permissions = const Value.absent(),
            Value<int> publinks = const Value.absent(),
            Value<DateTime?> lastRefresh = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResourcesCompanion(
            id: id,
            parent: parent,
            name: name,
            dir: dir,
            created: created,
            modified: modified,
            deleted: deleted,
            contentSize: contentSize,
            contentSha256: contentSha256,
            contentType: contentType,
            permissions: permissions,
            publinks: publinks,
            lastRefresh: lastRefresh,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parent = const Value.absent(),
            required String name,
            required bool dir,
            Value<DateTime?> created = const Value.absent(),
            Value<DateTime?> modified = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> contentSize = const Value.absent(),
            Value<String> contentSha256 = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> permissions = const Value.absent(),
            Value<int> publinks = const Value.absent(),
            Value<DateTime?> lastRefresh = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ResourcesCompanion.insert(
            id: id,
            parent: parent,
            name: name,
            dir: dir,
            created: created,
            modified: modified,
            deleted: deleted,
            contentSize: contentSize,
            contentSha256: contentSha256,
            contentType: contentType,
            permissions: permissions,
            publinks: publinks,
            lastRefresh: lastRefresh,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $ResourcesProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Resources,
    Resource,
    $ResourcesFilterComposer,
    $ResourcesOrderingComposer,
    $ResourcesAnnotationComposer,
    $ResourcesCreateCompanionBuilder,
    $ResourcesUpdateCompanionBuilder,
    (Resource, BaseReferences<_$AppDatabase, Resources, Resource>),
    Resource,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $UsersTableManager get users => $UsersTableManager(_db, _db.users);
  $ResourcesTableManager get resources =>
      $ResourcesTableManager(_db, _db.resources);
}

class ParentsResult {
  final String id;
  final String? parent;
  final String name;
  final String? permissions;
  ParentsResult({
    required this.id,
    this.parent,
    required this.name,
    this.permissions,
  });
}
