import 'package:drift/drift.dart';
import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/network.dart';

part 'network_dao.g.dart';

@DriftAccessor(tables: [Network])
class NetworkDao extends DatabaseAccessor<AppDatabase> with _$NetworkDaoMixin {

  NetworkDao(super.attachedDatabase);

  // Getters
  Future<List<NetworkData>> getAllNetworks() => select(network).get();


  // Setters
  Future<int> insertNetwork(NetworkCompanion networkCompanion) => into(network).insert(networkCompanion);
}