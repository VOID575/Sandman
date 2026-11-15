import 'package:drift/drift.dart';
import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/network.dart';

part 'network_dao.g.dart';

@DriftAccessor(tables: [Network])
class NetworkDao extends DatabaseAccessor<AppDatabase> with _$NetworkDaoMixin {
  NetworkDao(super.attachedDatabase);

  // Getters
  Future<List<NetworkData>> getAllNetworks() => select(network).get();

  Future<NetworkData?> getNetworkById(int networkId) =>
      (select(network)..where((n) => n.id.equals(networkId))).getSingleOrNull();

  // Setters
  Future<int> insertNetwork(NetworkCompanion networkCompanion) =>
      into(network).insert(networkCompanion);

  Future<int> updateNetworkStatus({
    required int networkId,
    required bool isGatewayRunning,
    required int runningMachines,
  }) => (update(network)..where((n) => n.id.equals(networkId))).write(
    NetworkCompanion(
      isGatewayRunning: Value(isGatewayRunning),
      runningMachines: Value(runningMachines),
    ),
  );

  // "go" delete all rows matching the where clause
  Future<int> deleteNetwork(int networkId) =>
      (delete(network)..where((machine) => machine.id.equals(networkId))).go();
}
