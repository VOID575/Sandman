import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/machine.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // We use an in-memory database for tests
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'insertNetwork should be successful when no fields is missing',
    () async {
      // Arrange
      final networkCompanion = NetworkCompanion.insert(
        name: 'Test Network',
        description: 'A network for testing',
        routerIp: '192.168.1.1',
        routerPort: 8080,
        broadcastAddress: const Value('255.255.255.255'),
      );

      // Act
      final id = await database.networkDao.insertNetwork(networkCompanion);

      // Assert
      final allNetworks = await database.networkDao.getAllNetworks();

      expect(allNetworks.length, 1);
      expect(allNetworks.first.id, id);
      expect(allNetworks.first.name, 'Test Network');
      expect(allNetworks.first.description, 'A network for testing');
      expect(allNetworks.first.routerIp, '192.168.1.1');
      expect(allNetworks.first.routerPort, 8080);
      expect(allNetworks.first.runningMachines, 0); // Default value
      expect(allNetworks.first.isRouterRunning, false); // Default value
    },
  );

  test(
    'insertMachine should be successful when no fields is missing',
    () async {
      // Arrange
      final networkId = await database.networkDao.insertNetwork(
        NetworkCompanion.insert(
          name: 'Network for Machine',
          description: 'Desc',
          routerIp: '10.0.0.1',
          routerPort: 9,
          broadcastAddress: const Value('255.255.255.255'),
        ),
      );

      final machineCompanion = MachineCompanion.insert(
        networkId: networkId,
        name: 'Test Machine',
        tailscaleIp: '100.100.100.100',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        status: const Value(MachineStatus.online),
      );

      // Act
      final machineId = await database.machineDao.insertMachine(
        machineCompanion,
      );

      // Assert
      final machines = await database.machineDao.getAllMachines();

      expect(machines.length, 1);
      expect(machines.first.id, machineId);
      expect(machines.first.networkId, networkId);
      expect(machines.first.name, 'Test Machine');
      expect(machines.first.tailscaleIp, '100.100.100.100');
      expect(machines.first.macAddress, 'AA:BB:CC:DD:EE:FF');
      expect(machines.first.status, MachineStatus.online);
    },
  );

  test(
    'getMachineNetwork should be successful when a machine has the network id given in parameters ',
    () async {
      // Arrange
      final networkId = await database.networkDao.insertNetwork(
        NetworkCompanion.insert(
          name: 'Network for Machine',
          description: 'Desc',
          routerIp: '10.0.0.1',
          routerPort: 9,
          broadcastAddress: const Value('255.255.255.255'),
        ),
      );

      final machineCompanion = MachineCompanion.insert(
        networkId: networkId,
        name: 'Test Machine',
        tailscaleIp: '100.100.100.100',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        status: const Value(MachineStatus.online),
      );

      // Act
      final machineId = await database.machineDao.insertMachine(
        machineCompanion,
      );

      // Assert
      final machines = await database.machineDao.getMachinesForNetwork(
        networkId,
      );

      expect(machines.length, 1);
      expect(machines.first.id, machineId);
      expect(machines.first.networkId, networkId);
      expect(machines.first.name, 'Test Machine');
      expect(machines.first.tailscaleIp, '100.100.100.100');
      expect(machines.first.macAddress, 'AA:BB:CC:DD:EE:FF');
      expect(machines.first.status, MachineStatus.online);
    },
  );
}
