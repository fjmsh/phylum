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
  static const VerificationMeta _contentLengthMeta =
      const VerificationMeta('contentLength');
  late final GeneratedColumn<int> contentLength = GeneratedColumn<int>(
      'content_length', aliasedName, false,
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
  late final GeneratedColumn<String> publinks = GeneratedColumn<String>(
      'publinks', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: '');
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
        contentLength,
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
    if (data.containsKey('content_length')) {
      context.handle(
          _contentLengthMeta,
          contentLength.isAcceptableOrUnknown(
              data['content_length']!, _contentLengthMeta));
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
      contentLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}content_length'])!,
      contentSha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_sha256'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      permissions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}permissions']),
      publinks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}publinks']),
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
  final int contentLength;
  final String contentSha256;
  final String contentType;
  final String? permissions;
  final String? publinks;
  final DateTime? lastRefresh;
  const Resource(
      {required this.id,
      this.parent,
      required this.name,
      required this.dir,
      this.created,
      this.modified,
      required this.deleted,
      required this.contentLength,
      required this.contentSha256,
      required this.contentType,
      this.permissions,
      this.publinks,
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
    map['content_length'] = Variable<int>(contentLength);
    map['content_sha256'] = Variable<String>(contentSha256);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || permissions != null) {
      map['permissions'] = Variable<String>(permissions);
    }
    if (!nullToAbsent || publinks != null) {
      map['publinks'] = Variable<String>(publinks);
    }
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
      contentLength: Value(contentLength),
      contentSha256: Value(contentSha256),
      contentType: Value(contentType),
      permissions: permissions == null && nullToAbsent
          ? const Value.absent()
          : Value(permissions),
      publinks: publinks == null && nullToAbsent
          ? const Value.absent()
          : Value(publinks),
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
      contentLength: serializer.fromJson<int>(json['content_length']),
      contentSha256: serializer.fromJson<String>(json['content_sha256']),
      contentType: serializer.fromJson<String>(json['content_type']),
      permissions: serializer.fromJson<String?>(json['permissions']),
      publinks: serializer.fromJson<String?>(json['publinks']),
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
      'content_length': serializer.toJson<int>(contentLength),
      'content_sha256': serializer.toJson<String>(contentSha256),
      'content_type': serializer.toJson<String>(contentType),
      'permissions': serializer.toJson<String?>(permissions),
      'publinks': serializer.toJson<String?>(publinks),
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
          int? contentLength,
          String? contentSha256,
          String? contentType,
          Value<String?> permissions = const Value.absent(),
          Value<String?> publinks = const Value.absent(),
          Value<DateTime?> lastRefresh = const Value.absent()}) =>
      Resource(
        id: id ?? this.id,
        parent: parent.present ? parent.value : this.parent,
        name: name ?? this.name,
        dir: dir ?? this.dir,
        created: created.present ? created.value : this.created,
        modified: modified.present ? modified.value : this.modified,
        deleted: deleted ?? this.deleted,
        contentLength: contentLength ?? this.contentLength,
        contentSha256: contentSha256 ?? this.contentSha256,
        contentType: contentType ?? this.contentType,
        permissions: permissions.present ? permissions.value : this.permissions,
        publinks: publinks.present ? publinks.value : this.publinks,
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
      contentLength: data.contentLength.present
          ? data.contentLength.value
          : this.contentLength,
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
          ..write('contentLength: $contentLength, ')
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
      contentLength,
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
          other.contentLength == this.contentLength &&
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
  final Value<int> contentLength;
  final Value<String> contentSha256;
  final Value<String> contentType;
  final Value<String?> permissions;
  final Value<String?> publinks;
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
    this.contentLength = const Value.absent(),
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
    this.contentLength = const Value.absent(),
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
    Expression<int>? contentLength,
    Expression<String>? contentSha256,
    Expression<String>? contentType,
    Expression<String>? permissions,
    Expression<String>? publinks,
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
      if (contentLength != null) 'content_length': contentLength,
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
      Value<int>? contentLength,
      Value<String>? contentSha256,
      Value<String>? contentType,
      Value<String?>? permissions,
      Value<String?>? publinks,
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
      contentLength: contentLength ?? this.contentLength,
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
    if (contentLength.present) {
      map['content_length'] = Variable<int>(contentLength.value);
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
      map['publinks'] = Variable<String>(publinks.value);
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
          ..write('contentLength: $contentLength, ')
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

class Shared extends Table with TableInfo<Shared, SharedData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Shared(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES resources(id)');
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [resourceId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared';
  @override
  VerificationContext validateIntegrity(Insertable<SharedData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  SharedData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SharedData(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
    );
  }

  @override
  Shared createAlias(String alias) {
    return Shared(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SharedData extends DataClass implements Insertable<SharedData> {
  final String resourceId;
  final int seq;
  const SharedData({required this.resourceId, required this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SharedCompanion toCompanion(bool nullToAbsent) {
    return SharedCompanion(
      resourceId: Value(resourceId),
      seq: Value(seq),
    );
  }

  factory SharedData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedData(
      resourceId: serializer.fromJson<String>(json['resource_id']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resource_id': serializer.toJson<String>(resourceId),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SharedData copyWith({String? resourceId, int? seq}) => SharedData(
        resourceId: resourceId ?? this.resourceId,
        seq: seq ?? this.seq,
      );
  SharedData copyWithCompanion(SharedCompanion data) {
    return SharedData(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SharedData(')
          ..write('resourceId: $resourceId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharedData &&
          other.resourceId == this.resourceId &&
          other.seq == this.seq);
}

class SharedCompanion extends UpdateCompanion<SharedData> {
  final Value<String> resourceId;
  final Value<int> seq;
  final Value<int> rowid;
  const SharedCompanion({
    this.resourceId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SharedCompanion.insert({
    required String resourceId,
    required int seq,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        seq = Value(seq);
  static Insertable<SharedData> custom({
    Expression<String>? resourceId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SharedCompanion copyWith(
      {Value<String>? resourceId, Value<int>? seq, Value<int>? rowid}) {
    return SharedCompanion(
      resourceId: resourceId ?? this.resourceId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Recents extends Table with TableInfo<Recents, Recent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Recents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES resources(id)');
  static const VerificationMeta _accessedMeta =
      const VerificationMeta('accessed');
  late final GeneratedColumn<DateTime> accessed = GeneratedColumn<DateTime>(
      'accessed', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [resourceId, accessed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recents';
  @override
  VerificationContext validateIntegrity(Insertable<Recent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('accessed')) {
      context.handle(_accessedMeta,
          accessed.isAcceptableOrUnknown(data['accessed']!, _accessedMeta));
    } else if (isInserting) {
      context.missing(_accessedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  Recent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recent(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      accessed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}accessed'])!,
    );
  }

  @override
  Recents createAlias(String alias) {
    return Recents(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Recent extends DataClass implements Insertable<Recent> {
  final String resourceId;
  final DateTime accessed;
  const Recent({required this.resourceId, required this.accessed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['accessed'] = Variable<DateTime>(accessed);
    return map;
  }

  RecentsCompanion toCompanion(bool nullToAbsent) {
    return RecentsCompanion(
      resourceId: Value(resourceId),
      accessed: Value(accessed),
    );
  }

  factory Recent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recent(
      resourceId: serializer.fromJson<String>(json['resource_id']),
      accessed: serializer.fromJson<DateTime>(json['accessed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resource_id': serializer.toJson<String>(resourceId),
      'accessed': serializer.toJson<DateTime>(accessed),
    };
  }

  Recent copyWith({String? resourceId, DateTime? accessed}) => Recent(
        resourceId: resourceId ?? this.resourceId,
        accessed: accessed ?? this.accessed,
      );
  Recent copyWithCompanion(RecentsCompanion data) {
    return Recent(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      accessed: data.accessed.present ? data.accessed.value : this.accessed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recent(')
          ..write('resourceId: $resourceId, ')
          ..write('accessed: $accessed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, accessed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recent &&
          other.resourceId == this.resourceId &&
          other.accessed == this.accessed);
}

class RecentsCompanion extends UpdateCompanion<Recent> {
  final Value<String> resourceId;
  final Value<DateTime> accessed;
  final Value<int> rowid;
  const RecentsCompanion({
    this.resourceId = const Value.absent(),
    this.accessed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentsCompanion.insert({
    required String resourceId,
    required DateTime accessed,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        accessed = Value(accessed);
  static Insertable<Recent> custom({
    Expression<String>? resourceId,
    Expression<DateTime>? accessed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (accessed != null) 'accessed': accessed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentsCompanion copyWith(
      {Value<String>? resourceId,
      Value<DateTime>? accessed,
      Value<int>? rowid}) {
    return RecentsCompanion(
      resourceId: resourceId ?? this.resourceId,
      accessed: accessed ?? this.accessed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (accessed.present) {
      map['accessed'] = Variable<DateTime>(accessed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentsCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('accessed: $accessed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Bookmarks extends Table with TableInfo<Bookmarks, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Bookmarks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES resources(id)');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _createdMeta =
      const VerificationMeta('created');
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
      'created', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (deleted IN (0, 1))');
  @override
  List<GeneratedColumn> get $columns => [resourceId, name, created, deleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta,
          created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    } else if (isInserting) {
      context.missing(_deletedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
    );
  }

  @override
  Bookmarks createAlias(String alias) {
    return Bookmarks(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String resourceId;
  final String name;
  final int created;
  final bool deleted;
  const Bookmark(
      {required this.resourceId,
      required this.name,
      required this.created,
      required this.deleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['name'] = Variable<String>(name);
    map['created'] = Variable<int>(created);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      resourceId: Value(resourceId),
      name: Value(name),
      created: Value(created),
      deleted: Value(deleted),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      resourceId: serializer.fromJson<String>(json['resource_id']),
      name: serializer.fromJson<String>(json['name']),
      created: serializer.fromJson<int>(json['created']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resource_id': serializer.toJson<String>(resourceId),
      'name': serializer.toJson<String>(name),
      'created': serializer.toJson<int>(created),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  Bookmark copyWith(
          {String? resourceId, String? name, int? created, bool? deleted}) =>
      Bookmark(
        resourceId: resourceId ?? this.resourceId,
        name: name ?? this.name,
        created: created ?? this.created,
        deleted: deleted ?? this.deleted,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      name: data.name.present ? data.name.value : this.name,
      created: data.created.present ? data.created.value : this.created,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('resourceId: $resourceId, ')
          ..write('name: $name, ')
          ..write('created: $created, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, name, created, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.resourceId == this.resourceId &&
          other.name == this.name &&
          other.created == this.created &&
          other.deleted == this.deleted);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> resourceId;
  final Value<String> name;
  final Value<int> created;
  final Value<bool> deleted;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.resourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.created = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String resourceId,
    required String name,
    required int created,
    required bool deleted,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        name = Value(name),
        created = Value(created),
        deleted = Value(deleted);
  static Insertable<Bookmark> custom({
    Expression<String>? resourceId,
    Expression<String>? name,
    Expression<int>? created,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (name != null) 'name': name,
      if (created != null) 'created': created,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? name,
      Value<int>? created,
      Value<bool>? deleted,
      Value<int>? rowid}) {
    return BookmarksCompanion(
      resourceId: resourceId ?? this.resourceId,
      name: name ?? this.name,
      created: created ?? this.created,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('name: $name, ')
          ..write('created: $created, ')
          ..write('deleted: $deleted, ')
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
  late final Shared shared = Shared(this);
  late final Index sharedResources = Index('shared_resources',
      'CREATE INDEX IF NOT EXISTS shared_resources ON shared (seq)');
  late final Recents recents = Recents(this);
  late final Index recentAccesses = Index('recent_accesses',
      'CREATE INDEX IF NOT EXISTS recent_accesses ON recents (accessed DESC)');
  late final Bookmarks bookmarks = Bookmarks(this);
  late final Index orderedBookmarks = Index('ordered_bookmarks',
      'CREATE INDEX IF NOT EXISTS ordered_bookmarks ON bookmarks (created)');
  Selectable<Resource> selectShared() {
    return customSelect(
        'SELECT r.* FROM shared AS s LEFT JOIN resources AS r ON s.resource_id = r.id ORDER BY s.seq',
        variables: [],
        readsFrom: {
          shared,
          resources,
        }).asyncMap(resources.mapFromRow);
  }

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

  Selectable<Resource> selectRecents() {
    return customSelect(
        'SELECT r.* FROM recents AS h LEFT JOIN resources AS r ON h.resource_id = r.id ORDER BY h.accessed DESC',
        variables: [],
        readsFrom: {
          recents,
          resources,
        }).asyncMap(resources.mapFromRow);
  }

  Selectable<SelectBookmarksResult> selectBookmarks() {
    return customSelect(
        'SELECT resource_id, name, created FROM bookmarks WHERE deleted = 0 ORDER BY created ASC',
        variables: [],
        readsFrom: {
          bookmarks,
        }).map((QueryRow row) => SelectBookmarksResult(
          resourceId: row.read<String>('resource_id'),
          name: row.read<String>('name'),
          created: row.read<int>('created'),
        ));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        resources,
        shared,
        sharedResources,
        recents,
        recentAccesses,
        bookmarks,
        orderedBookmarks
      ];
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
  Value<int> contentLength,
  Value<String> contentSha256,
  Value<String> contentType,
  Value<String?> permissions,
  Value<String?> publinks,
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
  Value<int> contentLength,
  Value<String> contentSha256,
  Value<String> contentType,
  Value<String?> permissions,
  Value<String?> publinks,
  Value<DateTime?> lastRefresh,
  Value<int> rowid,
});

final class $ResourcesReferences
    extends BaseReferences<_$AppDatabase, Resources, Resource> {
  $ResourcesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Shared, List<SharedData>> _sharedRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shared,
          aliasName:
              $_aliasNameGenerator(db.resources.id, db.shared.resourceId));

  $SharedProcessedTableManager get sharedRefs {
    final manager = $SharedTableManager($_db, $_db.shared)
        .filter((f) => f.resourceId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_sharedRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<Recents, List<Recent>> _recentsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recents,
          aliasName:
              $_aliasNameGenerator(db.resources.id, db.recents.resourceId));

  $RecentsProcessedTableManager get recentsRefs {
    final manager = $RecentsTableManager($_db, $_db.recents)
        .filter((f) => f.resourceId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_recentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<Bookmarks, List<Bookmark>> _bookmarksRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bookmarks,
          aliasName:
              $_aliasNameGenerator(db.resources.id, db.bookmarks.resourceId));

  $BookmarksProcessedTableManager get bookmarksRefs {
    final manager = $BookmarksTableManager($_db, $_db.bookmarks)
        .filter((f) => f.resourceId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

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

  ColumnFilters<int> get contentLength => $composableBuilder(
      column: $table.contentLength, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentSha256 => $composableBuilder(
      column: $table.contentSha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publinks => $composableBuilder(
      column: $table.publinks, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastRefresh => $composableBuilder(
      column: $table.lastRefresh, builder: (column) => ColumnFilters(column));

  Expression<bool> sharedRefs(
      Expression<bool> Function($SharedFilterComposer f) f) {
    final $SharedFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shared,
        getReferencedColumn: (t) => t.resourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $SharedFilterComposer(
              $db: $db,
              $table: $db.shared,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recentsRefs(
      Expression<bool> Function($RecentsFilterComposer f) f) {
    final $RecentsFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recents,
        getReferencedColumn: (t) => t.resourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $RecentsFilterComposer(
              $db: $db,
              $table: $db.recents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
      Expression<bool> Function($BookmarksFilterComposer f) f) {
    final $BookmarksFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.resourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $BookmarksFilterComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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

  ColumnOrderings<int> get contentLength => $composableBuilder(
      column: $table.contentLength,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentSha256 => $composableBuilder(
      column: $table.contentSha256,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publinks => $composableBuilder(
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

  GeneratedColumn<int> get contentLength => $composableBuilder(
      column: $table.contentLength, builder: (column) => column);

  GeneratedColumn<String> get contentSha256 => $composableBuilder(
      column: $table.contentSha256, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<String> get permissions => $composableBuilder(
      column: $table.permissions, builder: (column) => column);

  GeneratedColumn<String> get publinks =>
      $composableBuilder(column: $table.publinks, builder: (column) => column);

  GeneratedColumn<DateTime> get lastRefresh => $composableBuilder(
      column: $table.lastRefresh, builder: (column) => column);

  Expression<T> sharedRefs<T extends Object>(
      Expression<T> Function($SharedAnnotationComposer a) f) {
    final $SharedAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shared,
        getReferencedColumn: (t) => t.resourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $SharedAnnotationComposer(
              $db: $db,
              $table: $db.shared,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recentsRefs<T extends Object>(
      Expression<T> Function($RecentsAnnotationComposer a) f) {
    final $RecentsAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recents,
        getReferencedColumn: (t) => t.resourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $RecentsAnnotationComposer(
              $db: $db,
              $table: $db.recents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
      Expression<T> Function($BookmarksAnnotationComposer a) f) {
    final $BookmarksAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.resourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $BookmarksAnnotationComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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
    (Resource, $ResourcesReferences),
    Resource,
    PrefetchHooks Function(
        {bool sharedRefs, bool recentsRefs, bool bookmarksRefs})> {
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
            Value<int> contentLength = const Value.absent(),
            Value<String> contentSha256 = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> permissions = const Value.absent(),
            Value<String?> publinks = const Value.absent(),
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
            contentLength: contentLength,
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
            Value<int> contentLength = const Value.absent(),
            Value<String> contentSha256 = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> permissions = const Value.absent(),
            Value<String?> publinks = const Value.absent(),
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
            contentLength: contentLength,
            contentSha256: contentSha256,
            contentType: contentType,
            permissions: permissions,
            publinks: publinks,
            lastRefresh: lastRefresh,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $ResourcesReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {sharedRefs = false,
              recentsRefs = false,
              bookmarksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sharedRefs) db.shared,
                if (recentsRefs) db.recents,
                if (bookmarksRefs) db.bookmarks
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sharedRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $ResourcesReferences._sharedRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $ResourcesReferences(db, table, p0).sharedRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.resourceId == item.id),
                        typedResults: items),
                  if (recentsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $ResourcesReferences._recentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $ResourcesReferences(db, table, p0).recentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.resourceId == item.id),
                        typedResults: items),
                  if (bookmarksRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $ResourcesReferences._bookmarksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $ResourcesReferences(db, table, p0).bookmarksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.resourceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
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
    (Resource, $ResourcesReferences),
    Resource,
    PrefetchHooks Function(
        {bool sharedRefs, bool recentsRefs, bool bookmarksRefs})>;
typedef $SharedCreateCompanionBuilder = SharedCompanion Function({
  required String resourceId,
  required int seq,
  Value<int> rowid,
});
typedef $SharedUpdateCompanionBuilder = SharedCompanion Function({
  Value<String> resourceId,
  Value<int> seq,
  Value<int> rowid,
});

final class $SharedReferences
    extends BaseReferences<_$AppDatabase, Shared, SharedData> {
  $SharedReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _resourceIdTable(_$AppDatabase db) => db.resources
      .createAlias($_aliasNameGenerator(db.shared.resourceId, db.resources.id));

  $ResourcesProcessedTableManager get resourceId {
    final manager = $ResourcesTableManager($_db, $_db.resources)
        .filter((f) => f.id($_item.resourceId!));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $SharedFilterComposer extends Composer<_$AppDatabase, Shared> {
  $SharedFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  $ResourcesFilterComposer get resourceId {
    final $ResourcesFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesFilterComposer(
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

class $SharedOrderingComposer extends Composer<_$AppDatabase, Shared> {
  $SharedOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  $ResourcesOrderingComposer get resourceId {
    final $ResourcesOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesOrderingComposer(
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

class $SharedAnnotationComposer extends Composer<_$AppDatabase, Shared> {
  $SharedAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  $ResourcesAnnotationComposer get resourceId {
    final $ResourcesAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesAnnotationComposer(
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

class $SharedTableManager extends RootTableManager<
    _$AppDatabase,
    Shared,
    SharedData,
    $SharedFilterComposer,
    $SharedOrderingComposer,
    $SharedAnnotationComposer,
    $SharedCreateCompanionBuilder,
    $SharedUpdateCompanionBuilder,
    (SharedData, $SharedReferences),
    SharedData,
    PrefetchHooks Function({bool resourceId})> {
  $SharedTableManager(_$AppDatabase db, Shared table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SharedFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SharedOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SharedAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SharedCompanion(
            resourceId: resourceId,
            seq: seq,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required int seq,
            Value<int> rowid = const Value.absent(),
          }) =>
              SharedCompanion.insert(
            resourceId: resourceId,
            seq: seq,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $SharedReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({resourceId = false}) {
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
                if (resourceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.resourceId,
                    referencedTable: $SharedReferences._resourceIdTable(db),
                    referencedColumn: $SharedReferences._resourceIdTable(db).id,
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

typedef $SharedProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Shared,
    SharedData,
    $SharedFilterComposer,
    $SharedOrderingComposer,
    $SharedAnnotationComposer,
    $SharedCreateCompanionBuilder,
    $SharedUpdateCompanionBuilder,
    (SharedData, $SharedReferences),
    SharedData,
    PrefetchHooks Function({bool resourceId})>;
typedef $RecentsCreateCompanionBuilder = RecentsCompanion Function({
  required String resourceId,
  required DateTime accessed,
  Value<int> rowid,
});
typedef $RecentsUpdateCompanionBuilder = RecentsCompanion Function({
  Value<String> resourceId,
  Value<DateTime> accessed,
  Value<int> rowid,
});

final class $RecentsReferences
    extends BaseReferences<_$AppDatabase, Recents, Recent> {
  $RecentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias(
          $_aliasNameGenerator(db.recents.resourceId, db.resources.id));

  $ResourcesProcessedTableManager get resourceId {
    final manager = $ResourcesTableManager($_db, $_db.resources)
        .filter((f) => f.id($_item.resourceId!));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $RecentsFilterComposer extends Composer<_$AppDatabase, Recents> {
  $RecentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get accessed => $composableBuilder(
      column: $table.accessed, builder: (column) => ColumnFilters(column));

  $ResourcesFilterComposer get resourceId {
    final $ResourcesFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesFilterComposer(
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

class $RecentsOrderingComposer extends Composer<_$AppDatabase, Recents> {
  $RecentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get accessed => $composableBuilder(
      column: $table.accessed, builder: (column) => ColumnOrderings(column));

  $ResourcesOrderingComposer get resourceId {
    final $ResourcesOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesOrderingComposer(
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

class $RecentsAnnotationComposer extends Composer<_$AppDatabase, Recents> {
  $RecentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get accessed =>
      $composableBuilder(column: $table.accessed, builder: (column) => column);

  $ResourcesAnnotationComposer get resourceId {
    final $ResourcesAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesAnnotationComposer(
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

class $RecentsTableManager extends RootTableManager<
    _$AppDatabase,
    Recents,
    Recent,
    $RecentsFilterComposer,
    $RecentsOrderingComposer,
    $RecentsAnnotationComposer,
    $RecentsCreateCompanionBuilder,
    $RecentsUpdateCompanionBuilder,
    (Recent, $RecentsReferences),
    Recent,
    PrefetchHooks Function({bool resourceId})> {
  $RecentsTableManager(_$AppDatabase db, Recents table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<DateTime> accessed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecentsCompanion(
            resourceId: resourceId,
            accessed: accessed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required DateTime accessed,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecentsCompanion.insert(
            resourceId: resourceId,
            accessed: accessed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map(
                  (e) => (e.readTable(table), $RecentsReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({resourceId = false}) {
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
                if (resourceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.resourceId,
                    referencedTable: $RecentsReferences._resourceIdTable(db),
                    referencedColumn:
                        $RecentsReferences._resourceIdTable(db).id,
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

typedef $RecentsProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Recents,
    Recent,
    $RecentsFilterComposer,
    $RecentsOrderingComposer,
    $RecentsAnnotationComposer,
    $RecentsCreateCompanionBuilder,
    $RecentsUpdateCompanionBuilder,
    (Recent, $RecentsReferences),
    Recent,
    PrefetchHooks Function({bool resourceId})>;
typedef $BookmarksCreateCompanionBuilder = BookmarksCompanion Function({
  required String resourceId,
  required String name,
  required int created,
  required bool deleted,
  Value<int> rowid,
});
typedef $BookmarksUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<String> resourceId,
  Value<String> name,
  Value<int> created,
  Value<bool> deleted,
  Value<int> rowid,
});

final class $BookmarksReferences
    extends BaseReferences<_$AppDatabase, Bookmarks, Bookmark> {
  $BookmarksReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias(
          $_aliasNameGenerator(db.bookmarks.resourceId, db.resources.id));

  $ResourcesProcessedTableManager get resourceId {
    final manager = $ResourcesTableManager($_db, $_db.resources)
        .filter((f) => f.id($_item.resourceId!));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $BookmarksFilterComposer extends Composer<_$AppDatabase, Bookmarks> {
  $BookmarksFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  $ResourcesFilterComposer get resourceId {
    final $ResourcesFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesFilterComposer(
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

class $BookmarksOrderingComposer extends Composer<_$AppDatabase, Bookmarks> {
  $BookmarksOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  $ResourcesOrderingComposer get resourceId {
    final $ResourcesOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesOrderingComposer(
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

class $BookmarksAnnotationComposer extends Composer<_$AppDatabase, Bookmarks> {
  $BookmarksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  $ResourcesAnnotationComposer get resourceId {
    final $ResourcesAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.resourceId,
        referencedTable: $db.resources,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $ResourcesAnnotationComposer(
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

class $BookmarksTableManager extends RootTableManager<
    _$AppDatabase,
    Bookmarks,
    Bookmark,
    $BookmarksFilterComposer,
    $BookmarksOrderingComposer,
    $BookmarksAnnotationComposer,
    $BookmarksCreateCompanionBuilder,
    $BookmarksUpdateCompanionBuilder,
    (Bookmark, $BookmarksReferences),
    Bookmark,
    PrefetchHooks Function({bool resourceId})> {
  $BookmarksTableManager(_$AppDatabase db, Bookmarks table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BookmarksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BookmarksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BookmarksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> created = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion(
            resourceId: resourceId,
            name: name,
            created: created,
            deleted: deleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String name,
            required int created,
            required bool deleted,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion.insert(
            resourceId: resourceId,
            name: name,
            created: created,
            deleted: deleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $BookmarksReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({resourceId = false}) {
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
                if (resourceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.resourceId,
                    referencedTable: $BookmarksReferences._resourceIdTable(db),
                    referencedColumn:
                        $BookmarksReferences._resourceIdTable(db).id,
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

typedef $BookmarksProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    Bookmarks,
    Bookmark,
    $BookmarksFilterComposer,
    $BookmarksOrderingComposer,
    $BookmarksAnnotationComposer,
    $BookmarksCreateCompanionBuilder,
    $BookmarksUpdateCompanionBuilder,
    (Bookmark, $BookmarksReferences),
    Bookmark,
    PrefetchHooks Function({bool resourceId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $UsersTableManager get users => $UsersTableManager(_db, _db.users);
  $ResourcesTableManager get resources =>
      $ResourcesTableManager(_db, _db.resources);
  $SharedTableManager get shared => $SharedTableManager(_db, _db.shared);
  $RecentsTableManager get recents => $RecentsTableManager(_db, _db.recents);
  $BookmarksTableManager get bookmarks =>
      $BookmarksTableManager(_db, _db.bookmarks);
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

class SelectBookmarksResult {
  final String resourceId;
  final String name;
  final int created;
  SelectBookmarksResult({
    required this.resourceId,
    required this.name,
    required this.created,
  });
}
