import 'package:drift/drift.dart' hide isNotNull;
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
        gatewayIp: '192.168.1.1',
        gatewayPort: 8080,
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
      expect(allNetworks.first.gatewayIp, '192.168.1.1');
      expect(allNetworks.first.gatewayPort, 8080);
      expect(allNetworks.first.runningMachines, 0); // Default value
      expect(allNetworks.first.isGatewayRunning, false); // Default value
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
          gatewayIp: '10.0.0.1',
          gatewayPort: 9,
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
          gatewayIp: '10.0.0.1',
          gatewayPort: 9,
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

  test(
    'updateMachineStatus and updateNetworkStatus should persist changes',
    () async {
      final networkId = await database.networkDao.insertNetwork(
        NetworkCompanion.insert(
          name: 'Home',
          description: 'Home net',
          gatewayIp: '100.100.100.1',
          gatewayPort: 8080,
        ),
      );

      final machineId = await database.machineDao.insertMachine(
        MachineCompanion.insert(
          networkId: networkId,
          name: 'Workstation',
          tailscaleIp: '100.100.100.20',
          macAddress: 'AA:BB:CC:DD:EE:01',
          status: const Value(MachineStatus.offline),
        ),
      );

      await database.machineDao.updateMachineStatus(
        machineId,
        MachineStatus.online,
      );
      await database.networkDao.updateNetworkStatus(
        networkId: networkId,
        isGatewayRunning: true,
        runningMachines: 1,
      );

      final updatedMachine = (await database.machineDao.getMachinesForNetwork(
        networkId,
      )).first;
      final updatedNetwork = await database.networkDao.getNetworkById(
        networkId,
      );

      expect(updatedMachine.status, MachineStatus.online);
      expect(updatedNetwork, isNotNull);
      expect(updatedNetwork!.isGatewayRunning, isTrue);
      expect(updatedNetwork.runningMachines, 1);
    },
  );

  test('migrates v4 schema columns to v5 gateway columns', () async {
    await database.close();
    database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('''
            CREATE TABLE network (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              router_ip TEXT NOT NULL,
              router_mac_address TEXT NOT NULL DEFAULT '00:00:00:00:00:00',
              broadcast_address TEXT NOT NULL DEFAULT '255.255.255.255',
              router_port INTEGER NOT NULL,
              running_machines INTEGER NOT NULL DEFAULT 0,
              is_router_running INTEGER NOT NULL DEFAULT 0 CHECK (is_router_running IN (0, 1))
            );
          ''');
          rawDb.execute('''
            CREATE TABLE machine (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              network_id INTEGER NOT NULL REFERENCES network (id) ON DELETE CASCADE,
              name TEXT NOT NULL,
              tailscale_ip TEXT NOT NULL,
              mac_address TEXT NOT NULL,
              os TEXT NOT NULL DEFAULT 'linux',
              ssh_user TEXT NOT NULL DEFAULT 'root',
              status TEXT NOT NULL DEFAULT 'offline'
            );
          ''');
          rawDb.execute('''
            INSERT INTO network (name, description, router_ip, router_mac_address, broadcast_address, router_port, running_machines, is_router_running)
            VALUES ('Lab', 'Desc', '100.64.0.1', 'AA:BB:CC:DD:EE:FF', '192.168.1.255', 8080, 2, 1);
          ''');
          rawDb.execute('PRAGMA user_version = 4;');
        },
      ),
    );

    final networks = await database.networkDao.getAllNetworks();
    expect(networks, hasLength(1));
    expect(networks.single.gatewayIp, '100.64.0.1');
    expect(networks.single.gatewayMacAddress, 'AA:BB:CC:DD:EE:FF');
    expect(networks.single.gatewayPort, 8080);
    expect(networks.single.isGatewayRunning, isTrue);
    expect(networks.single.runningMachines, 2);
  });

  test(
    'migrates v2 schema to v5 without duplicating gateway_mac_address',
    () async {
      await database.close();
      database = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('''
            CREATE TABLE network (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              router_ip TEXT NOT NULL,
              broadcast_address TEXT NOT NULL DEFAULT '255.255.255.255',
              router_port INTEGER NOT NULL,
              running_machines INTEGER NOT NULL DEFAULT 0,
              is_router_running INTEGER NOT NULL DEFAULT 0 CHECK (is_router_running IN (0, 1))
            );
          ''');
            rawDb.execute('''
            CREATE TABLE machine (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              network_id INTEGER NOT NULL REFERENCES network (id) ON DELETE CASCADE,
              name TEXT NOT NULL,
              tailscale_ip TEXT NOT NULL,
              mac_address TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'offline'
            );
          ''');
            rawDb.execute('''
            INSERT INTO network (name, description, router_ip, broadcast_address, router_port)
            VALUES ('Legacy', 'Old v2', '100.64.0.2', '255.255.255.255', 8080);
          ''');
            rawDb.execute('PRAGMA user_version = 2;');
          },
        ),
      );

      final networks = await database.networkDao.getAllNetworks();
      expect(networks, hasLength(1));
      expect(networks.single.gatewayIp, '100.64.0.2');
      expect(networks.single.gatewayMacAddress, '00:00:00:00:00:00');
      expect(networks.single.gatewayPort, 8080);
      expect(networks.single.isGatewayRunning, isFalse);
    },
  );
}
