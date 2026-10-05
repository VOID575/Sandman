import 'package:drift/drift.dart';
import 'package:sandman/constants/db_contants.dart';
import 'package:sandman/models/network.dart';
import 'package:sandman/models/machine.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:drift/native.dart';
import 'dao/machine_dao.dart';
import 'dao/network_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Network, Machine], daos: [NetworkDao, MachineDao])
class AppDatabase extends _$AppDatabase {
  // Usage of super to call _$AppDatabase ctor with connection
  // : permits to execute instruction before object construction
  // Here we inline the function in chage of the database connection opening
  // to assert no other connection will ever be opened
  AppDatabase._privateConstructor()
    : super(
        LazyDatabase(() async {
          final dbFolder = await getApplicationDocumentsDirectory();
          final file = File(
            path.join(dbFolder.path, DbConstants.databaseFileName),
          );

          sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
          return NativeDatabase.createInBackground(file);
        }),
      );

  // Create an isolated in-memory database to execute tests in it
  AppDatabase.forTesting(super.e);

  // Create singleton to manipulate only one db connection
  static final AppDatabase instance = AppDatabase._privateConstructor();

  @override
  int get schemaVersion => 1;
}
