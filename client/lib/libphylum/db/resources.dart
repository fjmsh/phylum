import 'package:drift/drift.dart';

class Resources extends Table {
  TextColumn get id => text()();
  TextColumn get parent => text().nullable().references(Resources, #id)();
  TextColumn get name => text()();
  BoolColumn get dir => boolean()();
  DateTimeColumn get modified => dateTime()();
  IntColumn get size => integer()();
  TextColumn get sha256 => text()();
  TextColumn get contentType => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastFetch => dateTime().nullable()();
  TextColumn get permissions => text().nullable()();
  TextColumn get inherited => text().nullable()();
  IntColumn get publinks => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  // @override
  // List<Set<Column<Object>>>? get uniqueKeys => [
  //       {parent, name}
  //     ];
}
