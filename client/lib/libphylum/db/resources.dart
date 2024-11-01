import 'package:drift/drift.dart';

class Resources extends Table {
  TextColumn get id => text()();
  TextColumn get parent => text().nullable().references(Resources, #id)();
  TextColumn get name => text()();
  BoolColumn get dir => boolean()();
  DateTimeColumn get created => dateTime().nullable()();
  DateTimeColumn get modified => dateTime().nullable()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  IntColumn get contentSize => integer().withDefault(const Constant(0))();
  TextColumn get contentSha256 => text().withDefault(const Constant(""))();
  TextColumn get contentType => text().withDefault(const Constant(""))();
  TextColumn get permissions => text().nullable()();
  IntColumn get publinks => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRefresh => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // @override
  // List<Set<Column<Object>>>? get uniqueKeys => [
  //       {parent, name}
  //     ];
}
