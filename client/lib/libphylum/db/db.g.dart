// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class Users extends Table with TableInfo<Users, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, email, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
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
  final int id;
  final String email;
  final String name;
  const User({required this.id, required this.email, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['email'] = Variable<String>(email);
    map['name'] = Variable<String>(name);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      name: Value(name),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'email': serializer.toJson<String>(email),
      'name': serializer.toJson<String>(name),
    };
  }

  User copyWith({int? id, String? email, String? name}) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, email, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.name == this.name);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> email;
  final Value<String> name;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.name = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String email,
    required String name,
  }) : email = Value(email),
       name = Value(name);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? email,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? email,
    Value<String>? name,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name')
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
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  late final GeneratedColumn<String> parent = GeneratedColumn<String>(
    'parent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES resources(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dirMeta = const VerificationMeta('dir');
  late final GeneratedColumn<bool> dir = GeneratedColumn<bool>(
    'dir',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (dir IN (0, 1))',
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
    'modified',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  late final GeneratedColumn<DateTime> deleted = GeneratedColumn<DateTime>(
    'deleted',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _inheritedPermissionsMeta =
      const VerificationMeta('inheritedPermissions');
  late final GeneratedColumn<String> inheritedPermissions =
      GeneratedColumn<String>(
        'inherited_permissions',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _grantsMeta = const VerificationMeta('grants');
  late final GeneratedColumn<String> grants = GeneratedColumn<String>(
    'grants',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _userPermissionMeta = const VerificationMeta(
    'userPermission',
  );
  late final GeneratedColumn<int> userPermission = GeneratedColumn<int>(
    'user_permission',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastRefreshMeta = const VerificationMeta(
    'lastRefresh',
  );
  late final GeneratedColumn<DateTime> lastRefresh = GeneratedColumn<DateTime>(
    'last_refresh',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parent,
    name,
    dir,
    created,
    modified,
    deleted,
    inheritedPermissions,
    grants,
    userPermission,
    lastRefresh,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Resource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent')) {
      context.handle(
        _parentMeta,
        parent.isAcceptableOrUnknown(data['parent']!, _parentMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dir')) {
      context.handle(
        _dirMeta,
        dir.isAcceptableOrUnknown(data['dir']!, _dirMeta),
      );
    } else if (isInserting) {
      context.missing(_dirMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('inherited_permissions')) {
      context.handle(
        _inheritedPermissionsMeta,
        inheritedPermissions.isAcceptableOrUnknown(
          data['inherited_permissions']!,
          _inheritedPermissionsMeta,
        ),
      );
    }
    if (data.containsKey('grants')) {
      context.handle(
        _grantsMeta,
        grants.isAcceptableOrUnknown(data['grants']!, _grantsMeta),
      );
    }
    if (data.containsKey('user_permission')) {
      context.handle(
        _userPermissionMeta,
        userPermission.isAcceptableOrUnknown(
          data['user_permission']!,
          _userPermissionMeta,
        ),
      );
    }
    if (data.containsKey('last_refresh')) {
      context.handle(
        _lastRefreshMeta,
        lastRefresh.isAcceptableOrUnknown(
          data['last_refresh']!,
          _lastRefreshMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Resource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Resource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dir: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dir'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      ),
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted'],
      ),
      inheritedPermissions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inherited_permissions'],
      ),
      grants: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grants'],
      ),
      userPermission: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_permission'],
      )!,
      lastRefresh: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_refresh'],
      ),
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
  final DateTime? deleted;
  final String? inheritedPermissions;
  final String? grants;
  final int userPermission;
  final DateTime? lastRefresh;
  const Resource({
    required this.id,
    this.parent,
    required this.name,
    required this.dir,
    this.created,
    this.modified,
    this.deleted,
    this.inheritedPermissions,
    this.grants,
    required this.userPermission,
    this.lastRefresh,
  });
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
    if (!nullToAbsent || deleted != null) {
      map['deleted'] = Variable<DateTime>(deleted);
    }
    if (!nullToAbsent || inheritedPermissions != null) {
      map['inherited_permissions'] = Variable<String>(inheritedPermissions);
    }
    if (!nullToAbsent || grants != null) {
      map['grants'] = Variable<String>(grants);
    }
    map['user_permission'] = Variable<int>(userPermission);
    if (!nullToAbsent || lastRefresh != null) {
      map['last_refresh'] = Variable<DateTime>(lastRefresh);
    }
    return map;
  }

  ResourcesCompanion toCompanion(bool nullToAbsent) {
    return ResourcesCompanion(
      id: Value(id),
      parent: parent == null && nullToAbsent
          ? const Value.absent()
          : Value(parent),
      name: Value(name),
      dir: Value(dir),
      created: created == null && nullToAbsent
          ? const Value.absent()
          : Value(created),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      deleted: deleted == null && nullToAbsent
          ? const Value.absent()
          : Value(deleted),
      inheritedPermissions: inheritedPermissions == null && nullToAbsent
          ? const Value.absent()
          : Value(inheritedPermissions),
      grants: grants == null && nullToAbsent
          ? const Value.absent()
          : Value(grants),
      userPermission: Value(userPermission),
      lastRefresh: lastRefresh == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefresh),
    );
  }

  factory Resource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Resource(
      id: serializer.fromJson<String>(json['id']),
      parent: serializer.fromJson<String?>(json['parent']),
      name: serializer.fromJson<String>(json['name']),
      dir: serializer.fromJson<bool>(json['dir']),
      created: serializer.fromJson<DateTime?>(json['created']),
      modified: serializer.fromJson<DateTime?>(json['modified']),
      deleted: serializer.fromJson<DateTime?>(json['deleted']),
      inheritedPermissions: serializer.fromJson<String?>(
        json['inherited_permissions'],
      ),
      grants: serializer.fromJson<String?>(json['grants']),
      userPermission: serializer.fromJson<int>(json['user_permission']),
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
      'deleted': serializer.toJson<DateTime?>(deleted),
      'inherited_permissions': serializer.toJson<String?>(inheritedPermissions),
      'grants': serializer.toJson<String?>(grants),
      'user_permission': serializer.toJson<int>(userPermission),
      'last_refresh': serializer.toJson<DateTime?>(lastRefresh),
    };
  }

  Resource copyWith({
    String? id,
    Value<String?> parent = const Value.absent(),
    String? name,
    bool? dir,
    Value<DateTime?> created = const Value.absent(),
    Value<DateTime?> modified = const Value.absent(),
    Value<DateTime?> deleted = const Value.absent(),
    Value<String?> inheritedPermissions = const Value.absent(),
    Value<String?> grants = const Value.absent(),
    int? userPermission,
    Value<DateTime?> lastRefresh = const Value.absent(),
  }) => Resource(
    id: id ?? this.id,
    parent: parent.present ? parent.value : this.parent,
    name: name ?? this.name,
    dir: dir ?? this.dir,
    created: created.present ? created.value : this.created,
    modified: modified.present ? modified.value : this.modified,
    deleted: deleted.present ? deleted.value : this.deleted,
    inheritedPermissions: inheritedPermissions.present
        ? inheritedPermissions.value
        : this.inheritedPermissions,
    grants: grants.present ? grants.value : this.grants,
    userPermission: userPermission ?? this.userPermission,
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
      inheritedPermissions: data.inheritedPermissions.present
          ? data.inheritedPermissions.value
          : this.inheritedPermissions,
      grants: data.grants.present ? data.grants.value : this.grants,
      userPermission: data.userPermission.present
          ? data.userPermission.value
          : this.userPermission,
      lastRefresh: data.lastRefresh.present
          ? data.lastRefresh.value
          : this.lastRefresh,
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
          ..write('inheritedPermissions: $inheritedPermissions, ')
          ..write('grants: $grants, ')
          ..write('userPermission: $userPermission, ')
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
    inheritedPermissions,
    grants,
    userPermission,
    lastRefresh,
  );
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
          other.inheritedPermissions == this.inheritedPermissions &&
          other.grants == this.grants &&
          other.userPermission == this.userPermission &&
          other.lastRefresh == this.lastRefresh);
}

class ResourcesCompanion extends UpdateCompanion<Resource> {
  final Value<String> id;
  final Value<String?> parent;
  final Value<String> name;
  final Value<bool> dir;
  final Value<DateTime?> created;
  final Value<DateTime?> modified;
  final Value<DateTime?> deleted;
  final Value<String?> inheritedPermissions;
  final Value<String?> grants;
  final Value<int> userPermission;
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
    this.inheritedPermissions = const Value.absent(),
    this.grants = const Value.absent(),
    this.userPermission = const Value.absent(),
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
    this.inheritedPermissions = const Value.absent(),
    this.grants = const Value.absent(),
    this.userPermission = const Value.absent(),
    this.lastRefresh = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       dir = Value(dir);
  static Insertable<Resource> custom({
    Expression<String>? id,
    Expression<String>? parent,
    Expression<String>? name,
    Expression<bool>? dir,
    Expression<DateTime>? created,
    Expression<DateTime>? modified,
    Expression<DateTime>? deleted,
    Expression<String>? inheritedPermissions,
    Expression<String>? grants,
    Expression<int>? userPermission,
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
      if (inheritedPermissions != null)
        'inherited_permissions': inheritedPermissions,
      if (grants != null) 'grants': grants,
      if (userPermission != null) 'user_permission': userPermission,
      if (lastRefresh != null) 'last_refresh': lastRefresh,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResourcesCompanion copyWith({
    Value<String>? id,
    Value<String?>? parent,
    Value<String>? name,
    Value<bool>? dir,
    Value<DateTime?>? created,
    Value<DateTime?>? modified,
    Value<DateTime?>? deleted,
    Value<String?>? inheritedPermissions,
    Value<String?>? grants,
    Value<int>? userPermission,
    Value<DateTime?>? lastRefresh,
    Value<int>? rowid,
  }) {
    return ResourcesCompanion(
      id: id ?? this.id,
      parent: parent ?? this.parent,
      name: name ?? this.name,
      dir: dir ?? this.dir,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      deleted: deleted ?? this.deleted,
      inheritedPermissions: inheritedPermissions ?? this.inheritedPermissions,
      grants: grants ?? this.grants,
      userPermission: userPermission ?? this.userPermission,
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
      map['deleted'] = Variable<DateTime>(deleted.value);
    }
    if (inheritedPermissions.present) {
      map['inherited_permissions'] = Variable<String>(
        inheritedPermissions.value,
      );
    }
    if (grants.present) {
      map['grants'] = Variable<String>(grants.value);
    }
    if (userPermission.present) {
      map['user_permission'] = Variable<int>(userPermission.value);
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
          ..write('inheritedPermissions: $inheritedPermissions, ')
          ..write('grants: $grants, ')
          ..write('userPermission: $userPermission, ')
          ..write('lastRefresh: $lastRefresh, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TrashedResources extends Table
    with TableInfo<TrashedResources, TrashedResource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TrashedResources(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES resources',
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trashed_resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrashedResource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrashedResource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrashedResource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  TrashedResources createAlias(String alias) {
    return TrashedResources(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class TrashedResource extends DataClass implements Insertable<TrashedResource> {
  final String id;
  const TrashedResource({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    return map;
  }

  TrashedResourcesCompanion toCompanion(bool nullToAbsent) {
    return TrashedResourcesCompanion(id: Value(id));
  }

  factory TrashedResource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrashedResource(id: serializer.fromJson<String>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<String>(id)};
  }

  TrashedResource copyWith({String? id}) => TrashedResource(id: id ?? this.id);
  TrashedResource copyWithCompanion(TrashedResourcesCompanion data) {
    return TrashedResource(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('TrashedResource(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrashedResource && other.id == this.id);
}

class TrashedResourcesCompanion extends UpdateCompanion<TrashedResource> {
  final Value<String> id;
  final Value<int> rowid;
  const TrashedResourcesCompanion({
    this.id = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrashedResourcesCompanion.insert({
    required String id,
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<TrashedResource> custom({
    Expression<String>? id,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrashedResourcesCompanion copyWith({Value<String>? id, Value<int>? rowid}) {
    return TrashedResourcesCompanion(
      id: id ?? this.id,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrashedResourcesCompanion(')
          ..write('id: $id, ')
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
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES resources(id)',
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [resourceId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared';
  @override
  VerificationContext validateIntegrity(
    Insertable<SharedData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
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
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
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
    return SharedCompanion(resourceId: Value(resourceId), seq: Value(seq));
  }

  factory SharedData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
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
  }) : resourceId = Value(resourceId),
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

  SharedCompanion copyWith({
    Value<String>? resourceId,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
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

class ResourceVersions extends Table
    with TableInfo<ResourceVersions, ResourceVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ResourceVersions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES resources(id)',
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (deleted IN (0, 1))',
  );
  static const VerificationMeta _imgresMeta = const VerificationMeta('imgres');
  late final GeneratedColumn<int> imgres = GeneratedColumn<int>(
    'imgres',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    resourceId,
    created,
    deleted,
    imgres,
    size,
    mimeType,
    sha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resource_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResourceVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedMeta);
    }
    if (data.containsKey('imgres')) {
      context.handle(
        _imgresMeta,
        imgres.isAcceptableOrUnknown(data['imgres']!, _imgresMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResourceVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResourceVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      imgres: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imgres'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
    );
  }

  @override
  ResourceVersions createAlias(String alias) {
    return ResourceVersions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ResourceVersion extends DataClass implements Insertable<ResourceVersion> {
  final String id;
  final String resourceId;
  final DateTime created;
  final bool deleted;
  final int imgres;
  final int size;
  final String mimeType;
  final String sha256;
  const ResourceVersion({
    required this.id,
    required this.resourceId,
    required this.created,
    required this.deleted,
    required this.imgres,
    required this.size,
    required this.mimeType,
    required this.sha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['resource_id'] = Variable<String>(resourceId);
    map['created'] = Variable<DateTime>(created);
    map['deleted'] = Variable<bool>(deleted);
    map['imgres'] = Variable<int>(imgres);
    map['size'] = Variable<int>(size);
    map['mime_type'] = Variable<String>(mimeType);
    map['sha256'] = Variable<String>(sha256);
    return map;
  }

  ResourceVersionsCompanion toCompanion(bool nullToAbsent) {
    return ResourceVersionsCompanion(
      id: Value(id),
      resourceId: Value(resourceId),
      created: Value(created),
      deleted: Value(deleted),
      imgres: Value(imgres),
      size: Value(size),
      mimeType: Value(mimeType),
      sha256: Value(sha256),
    );
  }

  factory ResourceVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResourceVersion(
      id: serializer.fromJson<String>(json['id']),
      resourceId: serializer.fromJson<String>(json['resource_id']),
      created: serializer.fromJson<DateTime>(json['created']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      imgres: serializer.fromJson<int>(json['imgres']),
      size: serializer.fromJson<int>(json['size']),
      mimeType: serializer.fromJson<String>(json['mime_type']),
      sha256: serializer.fromJson<String>(json['sha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'resource_id': serializer.toJson<String>(resourceId),
      'created': serializer.toJson<DateTime>(created),
      'deleted': serializer.toJson<bool>(deleted),
      'imgres': serializer.toJson<int>(imgres),
      'size': serializer.toJson<int>(size),
      'mime_type': serializer.toJson<String>(mimeType),
      'sha256': serializer.toJson<String>(sha256),
    };
  }

  ResourceVersion copyWith({
    String? id,
    String? resourceId,
    DateTime? created,
    bool? deleted,
    int? imgres,
    int? size,
    String? mimeType,
    String? sha256,
  }) => ResourceVersion(
    id: id ?? this.id,
    resourceId: resourceId ?? this.resourceId,
    created: created ?? this.created,
    deleted: deleted ?? this.deleted,
    imgres: imgres ?? this.imgres,
    size: size ?? this.size,
    mimeType: mimeType ?? this.mimeType,
    sha256: sha256 ?? this.sha256,
  );
  ResourceVersion copyWithCompanion(ResourceVersionsCompanion data) {
    return ResourceVersion(
      id: data.id.present ? data.id.value : this.id,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      created: data.created.present ? data.created.value : this.created,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      imgres: data.imgres.present ? data.imgres.value : this.imgres,
      size: data.size.present ? data.size.value : this.size,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResourceVersion(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('created: $created, ')
          ..write('deleted: $deleted, ')
          ..write('imgres: $imgres, ')
          ..write('size: $size, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    resourceId,
    created,
    deleted,
    imgres,
    size,
    mimeType,
    sha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResourceVersion &&
          other.id == this.id &&
          other.resourceId == this.resourceId &&
          other.created == this.created &&
          other.deleted == this.deleted &&
          other.imgres == this.imgres &&
          other.size == this.size &&
          other.mimeType == this.mimeType &&
          other.sha256 == this.sha256);
}

class ResourceVersionsCompanion extends UpdateCompanion<ResourceVersion> {
  final Value<String> id;
  final Value<String> resourceId;
  final Value<DateTime> created;
  final Value<bool> deleted;
  final Value<int> imgres;
  final Value<int> size;
  final Value<String> mimeType;
  final Value<String> sha256;
  final Value<int> rowid;
  const ResourceVersionsCompanion({
    this.id = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.created = const Value.absent(),
    this.deleted = const Value.absent(),
    this.imgres = const Value.absent(),
    this.size = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResourceVersionsCompanion.insert({
    required String id,
    required String resourceId,
    required DateTime created,
    required bool deleted,
    this.imgres = const Value.absent(),
    required int size,
    required String mimeType,
    required String sha256,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       resourceId = Value(resourceId),
       created = Value(created),
       deleted = Value(deleted),
       size = Value(size),
       mimeType = Value(mimeType),
       sha256 = Value(sha256);
  static Insertable<ResourceVersion> custom({
    Expression<String>? id,
    Expression<String>? resourceId,
    Expression<DateTime>? created,
    Expression<bool>? deleted,
    Expression<int>? imgres,
    Expression<int>? size,
    Expression<String>? mimeType,
    Expression<String>? sha256,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resourceId != null) 'resource_id': resourceId,
      if (created != null) 'created': created,
      if (deleted != null) 'deleted': deleted,
      if (imgres != null) 'imgres': imgres,
      if (size != null) 'size': size,
      if (mimeType != null) 'mime_type': mimeType,
      if (sha256 != null) 'sha256': sha256,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResourceVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? resourceId,
    Value<DateTime>? created,
    Value<bool>? deleted,
    Value<int>? imgres,
    Value<int>? size,
    Value<String>? mimeType,
    Value<String>? sha256,
    Value<int>? rowid,
  }) {
    return ResourceVersionsCompanion(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      created: created ?? this.created,
      deleted: deleted ?? this.deleted,
      imgres: imgres ?? this.imgres,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      sha256: sha256 ?? this.sha256,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (imgres.present) {
      map['imgres'] = Variable<int>(imgres.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResourceVersionsCompanion(')
          ..write('id: $id, ')
          ..write('resourceId: $resourceId, ')
          ..write('created: $created, ')
          ..write('deleted: $deleted, ')
          ..write('imgres: $imgres, ')
          ..write('size: $size, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256: $sha256, ')
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
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES resources(id)',
  );
  static const VerificationMeta _accessedMeta = const VerificationMeta(
    'accessed',
  );
  late final GeneratedColumn<DateTime> accessed = GeneratedColumn<DateTime>(
    'accessed',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [resourceId, accessed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('accessed')) {
      context.handle(
        _accessedMeta,
        accessed.isAcceptableOrUnknown(data['accessed']!, _accessedMeta),
      );
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
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      )!,
      accessed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accessed'],
      )!,
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

  factory Recent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
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
  }) : resourceId = Value(resourceId),
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

  RecentsCompanion copyWith({
    Value<String>? resourceId,
    Value<DateTime>? accessed,
    Value<int>? rowid,
  }) {
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

class Publinks extends Table with TableInfo<Publinks, Publink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Publinks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _rootMeta = const VerificationMeta('root');
  late final GeneratedColumn<String> root = GeneratedColumn<String>(
    'root',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES resources(id)ON UPDATE CASCADE ON DELETE CASCADE',
  );
  static const VerificationMeta _accessedMeta = const VerificationMeta(
    'accessed',
  );
  late final GeneratedColumn<int> accessed = GeneratedColumn<int>(
    'accessed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _accessLimitMeta = const VerificationMeta(
    'accessLimit',
  );
  late final GeneratedColumn<int> accessLimit = GeneratedColumn<int>(
    'access_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _protectedMeta = const VerificationMeta(
    'protected',
  );
  late final GeneratedColumn<bool> protected = GeneratedColumn<bool>(
    'protected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (protected IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _expiresMeta = const VerificationMeta(
    'expires',
  );
  late final GeneratedColumn<DateTime> expires = GeneratedColumn<DateTime>(
    'expires',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    created,
    root,
    accessed,
    accessLimit,
    protected,
    expires,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'publinks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Publink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    }
    if (data.containsKey('root')) {
      context.handle(
        _rootMeta,
        root.isAcceptableOrUnknown(data['root']!, _rootMeta),
      );
    } else if (isInserting) {
      context.missing(_rootMeta);
    }
    if (data.containsKey('accessed')) {
      context.handle(
        _accessedMeta,
        accessed.isAcceptableOrUnknown(data['accessed']!, _accessedMeta),
      );
    }
    if (data.containsKey('access_limit')) {
      context.handle(
        _accessLimitMeta,
        accessLimit.isAcceptableOrUnknown(
          data['access_limit']!,
          _accessLimitMeta,
        ),
      );
    }
    if (data.containsKey('protected')) {
      context.handle(
        _protectedMeta,
        protected.isAcceptableOrUnknown(data['protected']!, _protectedMeta),
      );
    }
    if (data.containsKey('expires')) {
      context.handle(
        _expiresMeta,
        expires.isAcceptableOrUnknown(data['expires']!, _expiresMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Publink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Publink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      ),
      root: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root'],
      )!,
      accessed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accessed'],
      )!,
      accessLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}access_limit'],
      )!,
      protected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}protected'],
      )!,
      expires: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires'],
      ),
    );
  }

  @override
  Publinks createAlias(String alias) {
    return Publinks(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Publink extends DataClass implements Insertable<Publink> {
  final String id;
  final DateTime? created;
  final String root;
  final int accessed;
  final int accessLimit;
  final bool protected;
  final DateTime? expires;
  const Publink({
    required this.id,
    this.created,
    required this.root,
    required this.accessed,
    required this.accessLimit,
    required this.protected,
    this.expires,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || created != null) {
      map['created'] = Variable<DateTime>(created);
    }
    map['root'] = Variable<String>(root);
    map['accessed'] = Variable<int>(accessed);
    map['access_limit'] = Variable<int>(accessLimit);
    map['protected'] = Variable<bool>(protected);
    if (!nullToAbsent || expires != null) {
      map['expires'] = Variable<DateTime>(expires);
    }
    return map;
  }

  PublinksCompanion toCompanion(bool nullToAbsent) {
    return PublinksCompanion(
      id: Value(id),
      created: created == null && nullToAbsent
          ? const Value.absent()
          : Value(created),
      root: Value(root),
      accessed: Value(accessed),
      accessLimit: Value(accessLimit),
      protected: Value(protected),
      expires: expires == null && nullToAbsent
          ? const Value.absent()
          : Value(expires),
    );
  }

  factory Publink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Publink(
      id: serializer.fromJson<String>(json['id']),
      created: serializer.fromJson<DateTime?>(json['created']),
      root: serializer.fromJson<String>(json['root']),
      accessed: serializer.fromJson<int>(json['accessed']),
      accessLimit: serializer.fromJson<int>(json['access_limit']),
      protected: serializer.fromJson<bool>(json['protected']),
      expires: serializer.fromJson<DateTime?>(json['expires']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'created': serializer.toJson<DateTime?>(created),
      'root': serializer.toJson<String>(root),
      'accessed': serializer.toJson<int>(accessed),
      'access_limit': serializer.toJson<int>(accessLimit),
      'protected': serializer.toJson<bool>(protected),
      'expires': serializer.toJson<DateTime?>(expires),
    };
  }

  Publink copyWith({
    String? id,
    Value<DateTime?> created = const Value.absent(),
    String? root,
    int? accessed,
    int? accessLimit,
    bool? protected,
    Value<DateTime?> expires = const Value.absent(),
  }) => Publink(
    id: id ?? this.id,
    created: created.present ? created.value : this.created,
    root: root ?? this.root,
    accessed: accessed ?? this.accessed,
    accessLimit: accessLimit ?? this.accessLimit,
    protected: protected ?? this.protected,
    expires: expires.present ? expires.value : this.expires,
  );
  Publink copyWithCompanion(PublinksCompanion data) {
    return Publink(
      id: data.id.present ? data.id.value : this.id,
      created: data.created.present ? data.created.value : this.created,
      root: data.root.present ? data.root.value : this.root,
      accessed: data.accessed.present ? data.accessed.value : this.accessed,
      accessLimit: data.accessLimit.present
          ? data.accessLimit.value
          : this.accessLimit,
      protected: data.protected.present ? data.protected.value : this.protected,
      expires: data.expires.present ? data.expires.value : this.expires,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Publink(')
          ..write('id: $id, ')
          ..write('created: $created, ')
          ..write('root: $root, ')
          ..write('accessed: $accessed, ')
          ..write('accessLimit: $accessLimit, ')
          ..write('protected: $protected, ')
          ..write('expires: $expires')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, created, root, accessed, accessLimit, protected, expires);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Publink &&
          other.id == this.id &&
          other.created == this.created &&
          other.root == this.root &&
          other.accessed == this.accessed &&
          other.accessLimit == this.accessLimit &&
          other.protected == this.protected &&
          other.expires == this.expires);
}

class PublinksCompanion extends UpdateCompanion<Publink> {
  final Value<String> id;
  final Value<DateTime?> created;
  final Value<String> root;
  final Value<int> accessed;
  final Value<int> accessLimit;
  final Value<bool> protected;
  final Value<DateTime?> expires;
  final Value<int> rowid;
  const PublinksCompanion({
    this.id = const Value.absent(),
    this.created = const Value.absent(),
    this.root = const Value.absent(),
    this.accessed = const Value.absent(),
    this.accessLimit = const Value.absent(),
    this.protected = const Value.absent(),
    this.expires = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PublinksCompanion.insert({
    required String id,
    this.created = const Value.absent(),
    required String root,
    this.accessed = const Value.absent(),
    this.accessLimit = const Value.absent(),
    this.protected = const Value.absent(),
    this.expires = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       root = Value(root);
  static Insertable<Publink> custom({
    Expression<String>? id,
    Expression<DateTime>? created,
    Expression<String>? root,
    Expression<int>? accessed,
    Expression<int>? accessLimit,
    Expression<bool>? protected,
    Expression<DateTime>? expires,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (created != null) 'created': created,
      if (root != null) 'root': root,
      if (accessed != null) 'accessed': accessed,
      if (accessLimit != null) 'access_limit': accessLimit,
      if (protected != null) 'protected': protected,
      if (expires != null) 'expires': expires,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PublinksCompanion copyWith({
    Value<String>? id,
    Value<DateTime?>? created,
    Value<String>? root,
    Value<int>? accessed,
    Value<int>? accessLimit,
    Value<bool>? protected,
    Value<DateTime?>? expires,
    Value<int>? rowid,
  }) {
    return PublinksCompanion(
      id: id ?? this.id,
      created: created ?? this.created,
      root: root ?? this.root,
      accessed: accessed ?? this.accessed,
      accessLimit: accessLimit ?? this.accessLimit,
      protected: protected ?? this.protected,
      expires: expires ?? this.expires,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (root.present) {
      map['root'] = Variable<String>(root.value);
    }
    if (accessed.present) {
      map['accessed'] = Variable<int>(accessed.value);
    }
    if (accessLimit.present) {
      map['access_limit'] = Variable<int>(accessLimit.value);
    }
    if (protected.present) {
      map['protected'] = Variable<bool>(protected.value);
    }
    if (expires.present) {
      map['expires'] = Variable<DateTime>(expires.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PublinksCompanion(')
          ..write('id: $id, ')
          ..write('created: $created, ')
          ..write('root: $root, ')
          ..write('accessed: $accessed, ')
          ..write('accessLimit: $accessLimit, ')
          ..write('protected: $protected, ')
          ..write('expires: $expires, ')
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
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES resources(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dirMeta = const VerificationMeta('dir');
  late final GeneratedColumn<bool> dir = GeneratedColumn<bool>(
    'dir',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (deleted IN (0, 1))',
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (deleted IN (0, 1))',
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    resourceId,
    name,
    dir,
    created,
    deleted,
    mimeType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dir')) {
      context.handle(
        _dirMeta,
        dir.isAcceptableOrUnknown(data['dir']!, _dirMeta),
      );
    } else if (isInserting) {
      context.missing(_dirMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dir: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dir'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
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
  final bool dir;
  final int created;
  final bool deleted;
  final String? mimeType;
  const Bookmark({
    required this.resourceId,
    required this.name,
    required this.dir,
    required this.created,
    required this.deleted,
    this.mimeType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['name'] = Variable<String>(name);
    map['dir'] = Variable<bool>(dir);
    map['created'] = Variable<int>(created);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      resourceId: Value(resourceId),
      name: Value(name),
      dir: Value(dir),
      created: Value(created),
      deleted: Value(deleted),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      resourceId: serializer.fromJson<String>(json['resource_id']),
      name: serializer.fromJson<String>(json['name']),
      dir: serializer.fromJson<bool>(json['dir']),
      created: serializer.fromJson<int>(json['created']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      mimeType: serializer.fromJson<String?>(json['mime_type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resource_id': serializer.toJson<String>(resourceId),
      'name': serializer.toJson<String>(name),
      'dir': serializer.toJson<bool>(dir),
      'created': serializer.toJson<int>(created),
      'deleted': serializer.toJson<bool>(deleted),
      'mime_type': serializer.toJson<String?>(mimeType),
    };
  }

  Bookmark copyWith({
    String? resourceId,
    String? name,
    bool? dir,
    int? created,
    bool? deleted,
    Value<String?> mimeType = const Value.absent(),
  }) => Bookmark(
    resourceId: resourceId ?? this.resourceId,
    name: name ?? this.name,
    dir: dir ?? this.dir,
    created: created ?? this.created,
    deleted: deleted ?? this.deleted,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      name: data.name.present ? data.name.value : this.name,
      dir: data.dir.present ? data.dir.value : this.dir,
      created: data.created.present ? data.created.value : this.created,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('resourceId: $resourceId, ')
          ..write('name: $name, ')
          ..write('dir: $dir, ')
          ..write('created: $created, ')
          ..write('deleted: $deleted, ')
          ..write('mimeType: $mimeType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(resourceId, name, dir, created, deleted, mimeType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.resourceId == this.resourceId &&
          other.name == this.name &&
          other.dir == this.dir &&
          other.created == this.created &&
          other.deleted == this.deleted &&
          other.mimeType == this.mimeType);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> resourceId;
  final Value<String> name;
  final Value<bool> dir;
  final Value<int> created;
  final Value<bool> deleted;
  final Value<String?> mimeType;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.resourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.dir = const Value.absent(),
    this.created = const Value.absent(),
    this.deleted = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String resourceId,
    required String name,
    required bool dir,
    required int created,
    required bool deleted,
    this.mimeType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : resourceId = Value(resourceId),
       name = Value(name),
       dir = Value(dir),
       created = Value(created),
       deleted = Value(deleted);
  static Insertable<Bookmark> custom({
    Expression<String>? resourceId,
    Expression<String>? name,
    Expression<bool>? dir,
    Expression<int>? created,
    Expression<bool>? deleted,
    Expression<String>? mimeType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (name != null) 'name': name,
      if (dir != null) 'dir': dir,
      if (created != null) 'created': created,
      if (deleted != null) 'deleted': deleted,
      if (mimeType != null) 'mime_type': mimeType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? resourceId,
    Value<String>? name,
    Value<bool>? dir,
    Value<int>? created,
    Value<bool>? deleted,
    Value<String?>? mimeType,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      resourceId: resourceId ?? this.resourceId,
      name: name ?? this.name,
      dir: dir ?? this.dir,
      created: created ?? this.created,
      deleted: deleted ?? this.deleted,
      mimeType: mimeType ?? this.mimeType,
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
    if (dir.present) {
      map['dir'] = Variable<bool>(dir.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
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
          ..write('dir: $dir, ')
          ..write('created: $created, ')
          ..write('deleted: $deleted, ')
          ..write('mimeType: $mimeType, ')
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
  late final TrashedResources trashedResources = TrashedResources(this);
  late final Shared shared = Shared(this);
  late final Index sharedResources = Index(
    'shared_resources',
    'CREATE INDEX IF NOT EXISTS shared_resources ON shared (seq)',
  );
  late final ResourceVersions resourceVersions = ResourceVersions(this);
  late final Recents recents = Recents(this);
  late final Index recentAccesses = Index(
    'recent_accesses',
    'CREATE INDEX IF NOT EXISTS recent_accesses ON recents (accessed DESC)',
  );
  late final Publinks publinks = Publinks(this);
  late final Index publinksByRoot = Index(
    'publinks_by_root',
    'CREATE INDEX IF NOT EXISTS publinks_by_root ON publinks (root)',
  );
  late final Bookmarks bookmarks = Bookmarks(this);
  late final Index orderedBookmarks = Index(
    'ordered_bookmarks',
    'CREATE INDEX IF NOT EXISTS ordered_bookmarks ON bookmarks (created)',
  );
  Selectable<Resource> selectTrash() {
    return customSelect(
      'SELECT r.* FROM trashed_resources AS t JOIN resources AS r ON t.id = r.id ORDER BY r.deleted DESC',
      variables: [],
      readsFrom: {this.trashedResources, this.resources},
    ).asyncMap(this.resources.mapFromRow);
  }

  Selectable<Resource> selectShared() {
    return customSelect(
      'SELECT r.* FROM shared AS s LEFT JOIN resources AS r ON s.resource_id = r.id ORDER BY s.seq',
      variables: [],
      readsFrom: {this.shared, this.resources},
    ).asyncMap(this.resources.mapFromRow);
  }

  Selectable<ParentsResult> parents(String id) {
    return customSelect(
      'WITH RECURSIVE parents (id, parent, name, deleted, user_permission) AS (SELECT id, parent, name, deleted, user_permission FROM resources WHERE id = ?1 UNION SELECT r.id, r.parent, r.name, r.deleted, r.user_permission FROM resources AS r JOIN parents AS p ON r.id = p.parent) SELECT id, name, deleted, user_permission FROM parents',
      variables: [Variable<String>(id)],
      readsFrom: {this.resources},
    ).map(
      (QueryRow row) => ParentsResult(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        deleted: row.readNullable<DateTime>('deleted'),
        userPermission: row.read<int>('user_permission'),
      ),
    );
  }

  Selectable<PermissionsResult> permissions(String id) {
    return customSelect(
      'SELECT name, inherited_permissions, grants, user_permission FROM resources WHERE id = ?1',
      variables: [Variable<String>(id)],
      readsFrom: {this.resources},
    ).map(
      (QueryRow row) => PermissionsResult(
        name: row.read<String>('name'),
        inheritedPermissions: row.readNullable<String>('inherited_permissions'),
        grants: row.readNullable<String>('grants'),
        userPermission: row.read<int>('user_permission'),
      ),
    );
  }

  Selectable<ResourceVersion> latestVersion(String id) {
    return customSelect(
      'SELECT * FROM resource_versions WHERE resource_id = ?1 ORDER BY created DESC LIMIT 1',
      variables: [Variable<String>(id)],
      readsFrom: {this.resourceVersions},
    ).asyncMap(this.resourceVersions.mapFromRow);
  }

  Selectable<int> availableVersions(String id) {
    return customSelect(
      'SELECT COUNT(*) AS _c0 FROM resource_versions WHERE resource_id = ?1 AND deleted = 0',
      variables: [Variable<String>(id)],
      readsFrom: {this.resourceVersions},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<Resource> selectRecents() {
    return customSelect(
      'SELECT r.* FROM recents AS h INNER JOIN resources AS r ON h.resource_id = r.id WHERE r.deleted IS NULL AND r.parent IS NOT NULL ORDER BY h.accessed DESC',
      variables: [],
      readsFrom: {this.recents, this.resources},
    ).asyncMap(this.resources.mapFromRow);
  }

  Selectable<int> countPublinks(String root) {
    return customSelect(
      'SELECT COUNT(*) AS _c0 FROM publinks WHERE root = ?1',
      variables: [Variable<String>(root)],
      readsFrom: {this.publinks},
    ).map((QueryRow row) => row.read<int>('_c0'));
  }

  Selectable<Publink> selectPublinks(String root) {
    return customSelect(
      'SELECT * FROM publinks WHERE root = ?1',
      variables: [Variable<String>(root)],
      readsFrom: {this.publinks},
    ).asyncMap(this.publinks.mapFromRow);
  }

  Selectable<SelectBookmarksResult> selectBookmarks() {
    return customSelect(
      'SELECT resource_id, name, dir, created, mime_type FROM bookmarks WHERE deleted = 0 ORDER BY created ASC',
      variables: [],
      readsFrom: {this.bookmarks},
    ).map(
      (QueryRow row) => SelectBookmarksResult(
        resourceId: row.read<String>('resource_id'),
        name: row.read<String>('name'),
        dir: row.read<bool>('dir'),
        created: row.read<int>('created'),
        mimeType: row.readNullable<String>('mime_type'),
      ),
    );
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    resources,
    trashedResources,
    shared,
    sharedResources,
    resourceVersions,
    recents,
    recentAccesses,
    publinks,
    publinksByRoot,
    bookmarks,
    orderedBookmarks,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'resources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('publinks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'resources',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('publinks', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $UsersCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String email,
      required String name,
    });
typedef $UsersUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> email,
      Value<String> name,
    });

class $UsersFilterComposer extends Composer<_$AppDatabase, Users> {
  $UsersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $UsersOrderingComposer extends Composer<_$AppDatabase, Users> {
  $UsersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $UsersAnnotationComposer extends Composer<_$AppDatabase, Users> {
  $UsersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $UsersTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function()
        > {
  $UsersTableManager(_$AppDatabase db, Users table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $UsersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $UsersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $UsersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => UsersCompanion(id: id, email: email, name: name),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String email,
                required String name,
              }) => UsersCompanion.insert(id: id, email: email, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Users, User>(table),
                  BaseReferences<_$AppDatabase, Users, User>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $UsersProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function()
    >;
typedef $ResourcesCreateCompanionBuilder =
    ResourcesCompanion Function({
      required String id,
      Value<String?> parent,
      required String name,
      required bool dir,
      Value<DateTime?> created,
      Value<DateTime?> modified,
      Value<DateTime?> deleted,
      Value<String?> inheritedPermissions,
      Value<String?> grants,
      Value<int> userPermission,
      Value<DateTime?> lastRefresh,
      Value<int> rowid,
    });
typedef $ResourcesUpdateCompanionBuilder =
    ResourcesCompanion Function({
      Value<String> id,
      Value<String?> parent,
      Value<String> name,
      Value<bool> dir,
      Value<DateTime?> created,
      Value<DateTime?> modified,
      Value<DateTime?> deleted,
      Value<String?> inheritedPermissions,
      Value<String?> grants,
      Value<int> userPermission,
      Value<DateTime?> lastRefresh,
      Value<int> rowid,
    });

final class $ResourcesReferences
    extends BaseReferences<_$AppDatabase, Resources, Resource> {
  $ResourcesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _parentTable(_$AppDatabase db) =>
      db.resources.createAlias('resources__parent__resources__id');

  $ResourcesProcessedTableManager? get parent {
    final $_column = $_itemColumn<String>('parent');
    if ($_column == null) return null;
    final manager = $ResourcesTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Shared, List<SharedData>> _sharedRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shared,
    aliasName: 'resources__id__shared__resource_id',
  );

  $SharedProcessedTableManager get sharedRefs {
    final manager = $SharedTableManager(
      $_db,
      $_db.shared,
    ).filter((f) => f.resourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sharedRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ResourceVersions, List<ResourceVersion>>
  _resourceVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.resourceVersions,
    aliasName: 'resources__id__resource_versions__resource_id',
  );

  $ResourceVersionsProcessedTableManager get resourceVersionsRefs {
    final manager = $ResourceVersionsTableManager(
      $_db,
      $_db.resourceVersions,
    ).filter((f) => f.resourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _resourceVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Recents, List<Recent>> _recentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.recents,
    aliasName: 'resources__id__recents__resource_id',
  );

  $RecentsProcessedTableManager get recentsRefs {
    final manager = $RecentsTableManager(
      $_db,
      $_db.recents,
    ).filter((f) => f.resourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Publinks, List<Publink>> _publinksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.publinks,
    aliasName: 'resources__id__publinks__root',
  );

  $PublinksProcessedTableManager get publinksRefs {
    final manager = $PublinksTableManager(
      $_db,
      $_db.publinks,
    ).filter((f) => f.root.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_publinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Bookmarks, List<Bookmark>> _bookmarksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'resources__id__bookmarks__resource_id',
  );

  $BookmarksProcessedTableManager get bookmarksRefs {
    final manager = $BookmarksTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.resourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dir => $composableBuilder(
    column: $table.dir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inheritedPermissions => $composableBuilder(
    column: $table.inheritedPermissions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grants => $composableBuilder(
    column: $table.grants,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userPermission => $composableBuilder(
    column: $table.userPermission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRefresh => $composableBuilder(
    column: $table.lastRefresh,
    builder: (column) => ColumnFilters(column),
  );

  $ResourcesFilterComposer get parent {
    final $ResourcesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sharedRefs(
    Expression<bool> Function($SharedFilterComposer f) f,
  ) {
    final $SharedFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shared,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SharedFilterComposer(
            $db: $db,
            $table: $db.shared,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> resourceVersionsRefs(
    Expression<bool> Function($ResourceVersionsFilterComposer f) f,
  ) {
    final $ResourceVersionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resourceVersions,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourceVersionsFilterComposer(
            $db: $db,
            $table: $db.resourceVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recentsRefs(
    Expression<bool> Function($RecentsFilterComposer f) f,
  ) {
    final $RecentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recents,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecentsFilterComposer(
            $db: $db,
            $table: $db.recents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> publinksRefs(
    Expression<bool> Function($PublinksFilterComposer f) f,
  ) {
    final $PublinksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.publinks,
      getReferencedColumn: (t) => t.root,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PublinksFilterComposer(
            $db: $db,
            $table: $db.publinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($BookmarksFilterComposer f) f,
  ) {
    final $BookmarksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BookmarksFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dir => $composableBuilder(
    column: $table.dir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inheritedPermissions => $composableBuilder(
    column: $table.inheritedPermissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grants => $composableBuilder(
    column: $table.grants,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userPermission => $composableBuilder(
    column: $table.userPermission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRefresh => $composableBuilder(
    column: $table.lastRefresh,
    builder: (column) => ColumnOrderings(column),
  );

  $ResourcesOrderingComposer get parent {
    final $ResourcesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get dir =>
      $composableBuilder(column: $table.dir, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<DateTime> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get inheritedPermissions => $composableBuilder(
    column: $table.inheritedPermissions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grants =>
      $composableBuilder(column: $table.grants, builder: (column) => column);

  GeneratedColumn<int> get userPermission => $composableBuilder(
    column: $table.userPermission,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRefresh => $composableBuilder(
    column: $table.lastRefresh,
    builder: (column) => column,
  );

  $ResourcesAnnotationComposer get parent {
    final $ResourcesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parent,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sharedRefs<T extends Object>(
    Expression<T> Function($SharedAnnotationComposer a) f,
  ) {
    final $SharedAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shared,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SharedAnnotationComposer(
            $db: $db,
            $table: $db.shared,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> resourceVersionsRefs<T extends Object>(
    Expression<T> Function($ResourceVersionsAnnotationComposer a) f,
  ) {
    final $ResourceVersionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resourceVersions,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourceVersionsAnnotationComposer(
            $db: $db,
            $table: $db.resourceVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recentsRefs<T extends Object>(
    Expression<T> Function($RecentsAnnotationComposer a) f,
  ) {
    final $RecentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recents,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecentsAnnotationComposer(
            $db: $db,
            $table: $db.recents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> publinksRefs<T extends Object>(
    Expression<T> Function($PublinksAnnotationComposer a) f,
  ) {
    final $PublinksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.publinks,
      getReferencedColumn: (t) => t.root,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PublinksAnnotationComposer(
            $db: $db,
            $table: $db.publinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($BookmarksAnnotationComposer a) f,
  ) {
    final $BookmarksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.resourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BookmarksAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ResourcesTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function({
            bool parent,
            bool sharedRefs,
            bool resourceVersionsRefs,
            bool recentsRefs,
            bool publinksRefs,
            bool bookmarksRefs,
          })
        > {
  $ResourcesTableManager(_$AppDatabase db, Resources table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ResourcesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ResourcesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ResourcesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parent = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> dir = const Value.absent(),
                Value<DateTime?> created = const Value.absent(),
                Value<DateTime?> modified = const Value.absent(),
                Value<DateTime?> deleted = const Value.absent(),
                Value<String?> inheritedPermissions = const Value.absent(),
                Value<String?> grants = const Value.absent(),
                Value<int> userPermission = const Value.absent(),
                Value<DateTime?> lastRefresh = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResourcesCompanion(
                id: id,
                parent: parent,
                name: name,
                dir: dir,
                created: created,
                modified: modified,
                deleted: deleted,
                inheritedPermissions: inheritedPermissions,
                grants: grants,
                userPermission: userPermission,
                lastRefresh: lastRefresh,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parent = const Value.absent(),
                required String name,
                required bool dir,
                Value<DateTime?> created = const Value.absent(),
                Value<DateTime?> modified = const Value.absent(),
                Value<DateTime?> deleted = const Value.absent(),
                Value<String?> inheritedPermissions = const Value.absent(),
                Value<String?> grants = const Value.absent(),
                Value<int> userPermission = const Value.absent(),
                Value<DateTime?> lastRefresh = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResourcesCompanion.insert(
                id: id,
                parent: parent,
                name: name,
                dir: dir,
                created: created,
                modified: modified,
                deleted: deleted,
                inheritedPermissions: inheritedPermissions,
                grants: grants,
                userPermission: userPermission,
                lastRefresh: lastRefresh,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Resources, Resource>(table),
                  $ResourcesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parent = false,
                sharedRefs = false,
                resourceVersionsRefs = false,
                recentsRefs = false,
                publinksRefs = false,
                bookmarksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sharedRefs) db.shared,
                    if (resourceVersionsRefs) db.resourceVersions,
                    if (recentsRefs) db.recents,
                    if (publinksRefs) db.publinks,
                    if (bookmarksRefs) db.bookmarks,
                  ],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (parent) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parent,
                                    referencedTable: $ResourcesReferences
                                        ._parentTable(db),
                                    referencedColumn: $ResourcesReferences
                                        ._parentTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sharedRefs)
                        await $_getPrefetchedData<
                          Resource,
                          Resources,
                          SharedData
                        >(
                          currentTable: table,
                          referencedTable: $ResourcesReferences
                              ._sharedRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ResourcesReferences(db, table, p0).sharedRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (resourceVersionsRefs)
                        await $_getPrefetchedData<
                          Resource,
                          Resources,
                          ResourceVersion
                        >(
                          currentTable: table,
                          referencedTable: $ResourcesReferences
                              ._resourceVersionsRefsTable(db),
                          managerFromTypedResult: (p0) => $ResourcesReferences(
                            db,
                            table,
                            p0,
                          ).resourceVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recentsRefs)
                        await $_getPrefetchedData<Resource, Resources, Recent>(
                          currentTable: table,
                          referencedTable: $ResourcesReferences
                              ._recentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ResourcesReferences(db, table, p0).recentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (publinksRefs)
                        await $_getPrefetchedData<Resource, Resources, Publink>(
                          currentTable: table,
                          referencedTable: $ResourcesReferences
                              ._publinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ResourcesReferences(db, table, p0).publinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.root == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          Resource,
                          Resources,
                          Bookmark
                        >(
                          currentTable: table,
                          referencedTable: $ResourcesReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ResourcesReferences(db, table, p0).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ResourcesProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function({
        bool parent,
        bool sharedRefs,
        bool resourceVersionsRefs,
        bool recentsRefs,
        bool publinksRefs,
        bool bookmarksRefs,
      })
    >;
typedef $TrashedResourcesCreateCompanionBuilder =
    TrashedResourcesCompanion Function({required String id, Value<int> rowid});
typedef $TrashedResourcesUpdateCompanionBuilder =
    TrashedResourcesCompanion Function({Value<String> id, Value<int> rowid});

class $TrashedResourcesFilterComposer
    extends Composer<_$AppDatabase, TrashedResources> {
  $TrashedResourcesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $TrashedResourcesOrderingComposer
    extends Composer<_$AppDatabase, TrashedResources> {
  $TrashedResourcesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TrashedResourcesAnnotationComposer
    extends Composer<_$AppDatabase, TrashedResources> {
  $TrashedResourcesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $TrashedResourcesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TrashedResources,
          TrashedResource,
          $TrashedResourcesFilterComposer,
          $TrashedResourcesOrderingComposer,
          $TrashedResourcesAnnotationComposer,
          $TrashedResourcesCreateCompanionBuilder,
          $TrashedResourcesUpdateCompanionBuilder,
          (
            TrashedResource,
            BaseReferences<_$AppDatabase, TrashedResources, TrashedResource>,
          ),
          TrashedResource,
          PrefetchHooks Function()
        > {
  $TrashedResourcesTableManager(_$AppDatabase db, TrashedResources table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TrashedResourcesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TrashedResourcesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TrashedResourcesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrashedResourcesCompanion(id: id, rowid: rowid),
          createCompanionCallback:
              ({required String id, Value<int> rowid = const Value.absent()}) =>
                  TrashedResourcesCompanion.insert(id: id, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TrashedResources, TrashedResource>(table),
                  BaseReferences<
                    _$AppDatabase,
                    TrashedResources,
                    TrashedResource
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TrashedResourcesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TrashedResources,
      TrashedResource,
      $TrashedResourcesFilterComposer,
      $TrashedResourcesOrderingComposer,
      $TrashedResourcesAnnotationComposer,
      $TrashedResourcesCreateCompanionBuilder,
      $TrashedResourcesUpdateCompanionBuilder,
      (
        TrashedResource,
        BaseReferences<_$AppDatabase, TrashedResources, TrashedResource>,
      ),
      TrashedResource,
      PrefetchHooks Function()
    >;
typedef $SharedCreateCompanionBuilder =
    SharedCompanion Function({
      required String resourceId,
      required int seq,
      Value<int> rowid,
    });
typedef $SharedUpdateCompanionBuilder =
    SharedCompanion Function({
      Value<String> resourceId,
      Value<int> seq,
      Value<int> rowid,
    });

final class $SharedReferences
    extends BaseReferences<_$AppDatabase, Shared, SharedData> {
  $SharedReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias('shared__resource_id__resources__id');

  $ResourcesProcessedTableManager get resourceId {
    final $_column = $_itemColumn<String>('resource_id')!;

    final manager = $ResourcesTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
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
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  $ResourcesFilterComposer get resourceId {
    final $ResourcesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  $ResourcesOrderingComposer get resourceId {
    final $ResourcesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SharedTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function({bool resourceId})
        > {
  $SharedTableManager(_$AppDatabase db, Shared table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SharedFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SharedOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SharedAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> resourceId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SharedCompanion(
                resourceId: resourceId,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resourceId,
                required int seq,
                Value<int> rowid = const Value.absent(),
              }) => SharedCompanion.insert(
                resourceId: resourceId,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Shared, SharedData>(table),
                  $SharedReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (resourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resourceId,
                                referencedTable: $SharedReferences
                                    ._resourceIdTable(db),
                                referencedColumn: $SharedReferences
                                    ._resourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $SharedProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function({bool resourceId})
    >;
typedef $ResourceVersionsCreateCompanionBuilder =
    ResourceVersionsCompanion Function({
      required String id,
      required String resourceId,
      required DateTime created,
      required bool deleted,
      Value<int> imgres,
      required int size,
      required String mimeType,
      required String sha256,
      Value<int> rowid,
    });
typedef $ResourceVersionsUpdateCompanionBuilder =
    ResourceVersionsCompanion Function({
      Value<String> id,
      Value<String> resourceId,
      Value<DateTime> created,
      Value<bool> deleted,
      Value<int> imgres,
      Value<int> size,
      Value<String> mimeType,
      Value<String> sha256,
      Value<int> rowid,
    });

final class $ResourceVersionsReferences
    extends BaseReferences<_$AppDatabase, ResourceVersions, ResourceVersion> {
  $ResourceVersionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias('resource_versions__resource_id__resources__id');

  $ResourcesProcessedTableManager get resourceId {
    final $_column = $_itemColumn<String>('resource_id')!;

    final manager = $ResourcesTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ResourceVersionsFilterComposer
    extends Composer<_$AppDatabase, ResourceVersions> {
  $ResourceVersionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get imgres => $composableBuilder(
    column: $table.imgres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  $ResourcesFilterComposer get resourceId {
    final $ResourcesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ResourceVersionsOrderingComposer
    extends Composer<_$AppDatabase, ResourceVersions> {
  $ResourceVersionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get imgres => $composableBuilder(
    column: $table.imgres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  $ResourcesOrderingComposer get resourceId {
    final $ResourcesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ResourceVersionsAnnotationComposer
    extends Composer<_$AppDatabase, ResourceVersions> {
  $ResourceVersionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get imgres =>
      $composableBuilder(column: $table.imgres, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  $ResourcesAnnotationComposer get resourceId {
    final $ResourcesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ResourceVersionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ResourceVersions,
          ResourceVersion,
          $ResourceVersionsFilterComposer,
          $ResourceVersionsOrderingComposer,
          $ResourceVersionsAnnotationComposer,
          $ResourceVersionsCreateCompanionBuilder,
          $ResourceVersionsUpdateCompanionBuilder,
          (ResourceVersion, $ResourceVersionsReferences),
          ResourceVersion,
          PrefetchHooks Function({bool resourceId})
        > {
  $ResourceVersionsTableManager(_$AppDatabase db, ResourceVersions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ResourceVersionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ResourceVersionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ResourceVersionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> resourceId = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> imgres = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResourceVersionsCompanion(
                id: id,
                resourceId: resourceId,
                created: created,
                deleted: deleted,
                imgres: imgres,
                size: size,
                mimeType: mimeType,
                sha256: sha256,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String resourceId,
                required DateTime created,
                required bool deleted,
                Value<int> imgres = const Value.absent(),
                required int size,
                required String mimeType,
                required String sha256,
                Value<int> rowid = const Value.absent(),
              }) => ResourceVersionsCompanion.insert(
                id: id,
                resourceId: resourceId,
                created: created,
                deleted: deleted,
                imgres: imgres,
                size: size,
                mimeType: mimeType,
                sha256: sha256,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ResourceVersions, ResourceVersion>(table),
                  $ResourceVersionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (resourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resourceId,
                                referencedTable: $ResourceVersionsReferences
                                    ._resourceIdTable(db),
                                referencedColumn: $ResourceVersionsReferences
                                    ._resourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ResourceVersionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ResourceVersions,
      ResourceVersion,
      $ResourceVersionsFilterComposer,
      $ResourceVersionsOrderingComposer,
      $ResourceVersionsAnnotationComposer,
      $ResourceVersionsCreateCompanionBuilder,
      $ResourceVersionsUpdateCompanionBuilder,
      (ResourceVersion, $ResourceVersionsReferences),
      ResourceVersion,
      PrefetchHooks Function({bool resourceId})
    >;
typedef $RecentsCreateCompanionBuilder =
    RecentsCompanion Function({
      required String resourceId,
      required DateTime accessed,
      Value<int> rowid,
    });
typedef $RecentsUpdateCompanionBuilder =
    RecentsCompanion Function({
      Value<String> resourceId,
      Value<DateTime> accessed,
      Value<int> rowid,
    });

final class $RecentsReferences
    extends BaseReferences<_$AppDatabase, Recents, Recent> {
  $RecentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias('recents__resource_id__resources__id');

  $ResourcesProcessedTableManager get resourceId {
    final $_column = $_itemColumn<String>('resource_id')!;

    final manager = $ResourcesTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
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
    column: $table.accessed,
    builder: (column) => ColumnFilters(column),
  );

  $ResourcesFilterComposer get resourceId {
    final $ResourcesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.accessed,
    builder: (column) => ColumnOrderings(column),
  );

  $ResourcesOrderingComposer get resourceId {
    final $ResourcesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecentsTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function({bool resourceId})
        > {
  $RecentsTableManager(_$AppDatabase db, Recents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> resourceId = const Value.absent(),
                Value<DateTime> accessed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentsCompanion(
                resourceId: resourceId,
                accessed: accessed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resourceId,
                required DateTime accessed,
                Value<int> rowid = const Value.absent(),
              }) => RecentsCompanion.insert(
                resourceId: resourceId,
                accessed: accessed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Recents, Recent>(table),
                  $RecentsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (resourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resourceId,
                                referencedTable: $RecentsReferences
                                    ._resourceIdTable(db),
                                referencedColumn: $RecentsReferences
                                    ._resourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $RecentsProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function({bool resourceId})
    >;
typedef $PublinksCreateCompanionBuilder =
    PublinksCompanion Function({
      required String id,
      Value<DateTime?> created,
      required String root,
      Value<int> accessed,
      Value<int> accessLimit,
      Value<bool> protected,
      Value<DateTime?> expires,
      Value<int> rowid,
    });
typedef $PublinksUpdateCompanionBuilder =
    PublinksCompanion Function({
      Value<String> id,
      Value<DateTime?> created,
      Value<String> root,
      Value<int> accessed,
      Value<int> accessLimit,
      Value<bool> protected,
      Value<DateTime?> expires,
      Value<int> rowid,
    });

final class $PublinksReferences
    extends BaseReferences<_$AppDatabase, Publinks, Publink> {
  $PublinksReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _rootTable(_$AppDatabase db) =>
      db.resources.createAlias('publinks__root__resources__id');

  $ResourcesProcessedTableManager get root {
    final $_column = $_itemColumn<String>('root')!;

    final manager = $ResourcesTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rootTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PublinksFilterComposer extends Composer<_$AppDatabase, Publinks> {
  $PublinksFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accessed => $composableBuilder(
    column: $table.accessed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accessLimit => $composableBuilder(
    column: $table.accessLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get protected => $composableBuilder(
    column: $table.protected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnFilters(column),
  );

  $ResourcesFilterComposer get root {
    final $ResourcesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.root,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PublinksOrderingComposer extends Composer<_$AppDatabase, Publinks> {
  $PublinksOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accessed => $composableBuilder(
    column: $table.accessed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accessLimit => $composableBuilder(
    column: $table.accessLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get protected => $composableBuilder(
    column: $table.protected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnOrderings(column),
  );

  $ResourcesOrderingComposer get root {
    final $ResourcesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.root,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PublinksAnnotationComposer extends Composer<_$AppDatabase, Publinks> {
  $PublinksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get accessed =>
      $composableBuilder(column: $table.accessed, builder: (column) => column);

  GeneratedColumn<int> get accessLimit => $composableBuilder(
    column: $table.accessLimit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get protected =>
      $composableBuilder(column: $table.protected, builder: (column) => column);

  GeneratedColumn<DateTime> get expires =>
      $composableBuilder(column: $table.expires, builder: (column) => column);

  $ResourcesAnnotationComposer get root {
    final $ResourcesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.root,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PublinksTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Publinks,
          Publink,
          $PublinksFilterComposer,
          $PublinksOrderingComposer,
          $PublinksAnnotationComposer,
          $PublinksCreateCompanionBuilder,
          $PublinksUpdateCompanionBuilder,
          (Publink, $PublinksReferences),
          Publink,
          PrefetchHooks Function({bool root})
        > {
  $PublinksTableManager(_$AppDatabase db, Publinks table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PublinksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PublinksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PublinksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime?> created = const Value.absent(),
                Value<String> root = const Value.absent(),
                Value<int> accessed = const Value.absent(),
                Value<int> accessLimit = const Value.absent(),
                Value<bool> protected = const Value.absent(),
                Value<DateTime?> expires = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PublinksCompanion(
                id: id,
                created: created,
                root: root,
                accessed: accessed,
                accessLimit: accessLimit,
                protected: protected,
                expires: expires,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime?> created = const Value.absent(),
                required String root,
                Value<int> accessed = const Value.absent(),
                Value<int> accessLimit = const Value.absent(),
                Value<bool> protected = const Value.absent(),
                Value<DateTime?> expires = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PublinksCompanion.insert(
                id: id,
                created: created,
                root: root,
                accessed: accessed,
                accessLimit: accessLimit,
                protected: protected,
                expires: expires,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Publinks, Publink>(table),
                  $PublinksReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({root = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (root) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.root,
                                referencedTable: $PublinksReferences._rootTable(
                                  db,
                                ),
                                referencedColumn: $PublinksReferences
                                    ._rootTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $PublinksProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Publinks,
      Publink,
      $PublinksFilterComposer,
      $PublinksOrderingComposer,
      $PublinksAnnotationComposer,
      $PublinksCreateCompanionBuilder,
      $PublinksUpdateCompanionBuilder,
      (Publink, $PublinksReferences),
      Publink,
      PrefetchHooks Function({bool root})
    >;
typedef $BookmarksCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String resourceId,
      required String name,
      required bool dir,
      required int created,
      required bool deleted,
      Value<String?> mimeType,
      Value<int> rowid,
    });
typedef $BookmarksUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> resourceId,
      Value<String> name,
      Value<bool> dir,
      Value<int> created,
      Value<bool> deleted,
      Value<String?> mimeType,
      Value<int> rowid,
    });

final class $BookmarksReferences
    extends BaseReferences<_$AppDatabase, Bookmarks, Bookmark> {
  $BookmarksReferences(super.$_db, super.$_table, super.$_typedResult);

  static Resources _resourceIdTable(_$AppDatabase db) =>
      db.resources.createAlias('bookmarks__resource_id__resources__id');

  $ResourcesProcessedTableManager get resourceId {
    final $_column = $_itemColumn<String>('resource_id')!;

    final manager = $ResourcesTableManager(
      $_db,
      $_db.resources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
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
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dir => $composableBuilder(
    column: $table.dir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  $ResourcesFilterComposer get resourceId {
    final $ResourcesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesFilterComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dir => $composableBuilder(
    column: $table.dir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  $ResourcesOrderingComposer get resourceId {
    final $ResourcesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesOrderingComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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

  GeneratedColumn<bool> get dir =>
      $composableBuilder(column: $table.dir, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  $ResourcesAnnotationComposer get resourceId {
    final $ResourcesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resourceId,
      referencedTable: $db.resources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ResourcesAnnotationComposer(
            $db: $db,
            $table: $db.resources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $BookmarksTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function({bool resourceId})
        > {
  $BookmarksTableManager(_$AppDatabase db, Bookmarks table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BookmarksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BookmarksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BookmarksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> resourceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> dir = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                resourceId: resourceId,
                name: name,
                dir: dir,
                created: created,
                deleted: deleted,
                mimeType: mimeType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resourceId,
                required String name,
                required bool dir,
                required int created,
                required bool deleted,
                Value<String?> mimeType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                resourceId: resourceId,
                name: name,
                dir: dir,
                created: created,
                deleted: deleted,
                mimeType: mimeType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Bookmarks, Bookmark>(table),
                  $BookmarksReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (resourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resourceId,
                                referencedTable: $BookmarksReferences
                                    ._resourceIdTable(db),
                                referencedColumn: $BookmarksReferences
                                    ._resourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $BookmarksProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function({bool resourceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $UsersTableManager get users => $UsersTableManager(_db, _db.users);
  $ResourcesTableManager get resources =>
      $ResourcesTableManager(_db, _db.resources);
  $TrashedResourcesTableManager get trashedResources =>
      $TrashedResourcesTableManager(_db, _db.trashedResources);
  $SharedTableManager get shared => $SharedTableManager(_db, _db.shared);
  $ResourceVersionsTableManager get resourceVersions =>
      $ResourceVersionsTableManager(_db, _db.resourceVersions);
  $RecentsTableManager get recents => $RecentsTableManager(_db, _db.recents);
  $PublinksTableManager get publinks =>
      $PublinksTableManager(_db, _db.publinks);
  $BookmarksTableManager get bookmarks =>
      $BookmarksTableManager(_db, _db.bookmarks);
}

class ParentsResult {
  final String id;
  final String name;
  final DateTime? deleted;
  final int userPermission;
  ParentsResult({
    required this.id,
    required this.name,
    this.deleted,
    required this.userPermission,
  });
}

class PermissionsResult {
  final String name;
  final String? inheritedPermissions;
  final String? grants;
  final int userPermission;
  PermissionsResult({
    required this.name,
    this.inheritedPermissions,
    this.grants,
    required this.userPermission,
  });
}

class SelectBookmarksResult {
  final String resourceId;
  final String name;
  final bool dir;
  final int created;
  final String? mimeType;
  SelectBookmarksResult({
    required this.resourceId,
    required this.name,
    required this.dir,
    required this.created,
    this.mimeType,
  });
}
