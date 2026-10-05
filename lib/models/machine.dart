import 'package:drift/drift.dart';
import 'package:sandman/models/network.dart';

enum MachineStatus { online, offline, wakingUp, shuttingDown }

class Machine extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get networkId => integer().references(Network, #id)();

  TextColumn get name => text()();
  TextColumn get tailscaleIp => text()();
  TextColumn get macAddress => text()();

  IntColumn get status => intEnum<MachineStatus>().withDefault(const Constant(1))();
}