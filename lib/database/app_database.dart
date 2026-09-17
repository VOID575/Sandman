import 'package:drift/drift.dart';
import 'package:sandman/constants/db_contants.dart';
import 'package:sandman/models/network.dart';
import 'package:sandman/models/machine.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Network, Machine])
class AppDatabase extends _$AppDatabase {

  // Usage of super to call _$AppDatabase ctor with connection
  // : permits to execute instruction before object construction
  AppDatabase._privateConstructor() : super(_openConnection());
  
  // Create an isolated in-memory database to execute tests in it
  AppDatabase.forTesting(super.e);

  // Create singleton to manipulate only one db connection
  static final AppDatabase instance = AppDatabase._privateConstructor();

  @override
  int get schemaVersion => 1;

  // Implement 2 classes that inherits AppDatabase ?
  Future<List<MachineData>> getAllMachines() => select(machine).get();

  Future<int> insertNetwork(NetworkCompanion networkCompanion) => into(network).insert(networkCompanion);

  Future<List<MachineData>> getMachinesForNetwork(int networkId) {
    Future<List<MachineData>> machineNetwork = (select(machine)..where((n) => n.networkId.equals(networkId))).get();
    return machineNetwork;
  }

  Future<List<NetworkData>> getAllNetworks() => select(network).get();
  Future<int> insertMachine(MachineCompanion machineCompanion) => into(machine).insert(machineCompanion);

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, DbConstants.databaseFileName));

    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
    return NativeDatabase.createInBackground(file);
  });
}