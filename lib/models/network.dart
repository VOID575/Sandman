import 'package:drift/drift.dart';

// TODO : Add validators directly on the object, don't deleguate it to the front
class Network extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get gatewayIp => text()();
  TextColumn get gatewayMacAddress =>
      text().withDefault(const Constant('00:00:00:00:00:00'))();
  TextColumn get broadcastAddress =>
      text().withDefault(const Constant('255.255.255.255'))();

  IntColumn get gatewayPort => integer()();
  IntColumn get runningMachines => integer().withDefault(const Constant(0))();
  BoolColumn get isGatewayRunning =>
      boolean().withDefault(const Constant(false))();
}
