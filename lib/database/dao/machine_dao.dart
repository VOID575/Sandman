import 'package:drift/drift.dart';
import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/machine.dart';

part 'machine_dao.g.dart';

@DriftAccessor(tables: [Machine])
class MachineDao extends DatabaseAccessor<AppDatabase> with _$MachineDaoMixin {

  MachineDao(super.attachedDatabase);

  // Getters
  Future<List<MachineData>> getAllMachines() => select(machine).get();

  Future<List<MachineData>> getMachinesForNetwork(int networkId) {
    Future<List<MachineData>> machineNetwork = (select(machine)..where((n) => n.networkId.equals(networkId))).get();
    return machineNetwork;
  }


  // Setters
  Future<int> insertMachine(MachineCompanion machineCompanion) => into(machine).insert(machineCompanion);
}