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

  test('insertNetwork works correctly', () async {
    final networkCompanion = NetworkCompanion.insert(
      name: 'Test Network',
      description: 'A network for testing',
      routerIp: '192.168.1.1',
      routerPort: 8080,
    );

    final id = await database.insertNetwork(networkCompanion);
    
    final allNetworks = await database.getAllNetworks();
    
    expect(allNetworks.length, 1);
    expect(allNetworks.first.id, id);
    expect(allNetworks.first.name, 'Test Network');
    expect(allNetworks.first.description, 'A network for testing');
    expect(allNetworks.first.routerIp, '192.168.1.1');
    expect(allNetworks.first.routerPort, 8080);
    expect(allNetworks.first.runningMachines, 0); // Default value
    expect(allNetworks.first.isRouterRunning, false); // Default value
  });

  test('insertMachine works correctly and links to network', () async {
    // 1. Insert a network first to satisfy foreign key
    final networkId = await database.insertNetwork(NetworkCompanion.insert(
      name: 'Network for Machine',
      description: 'Desc',
      routerIp: '10.0.0.1',
      routerPort: 9,
    ));

    // 2. Insert a machine linked to the network
    final machineCompanion = MachineCompanion.insert(
      networkId: networkId,
      name: 'Test Machine',
      tailscaleIp: '100.100.100.100',
      macAddress: 'AA:BB:CC:DD:EE:FF',
      status: const Value(MachineStatus.online),
    );

    final machineId = await database.insertMachine(machineCompanion);

    // 3. Retrieve machines for that network
    final machines = await database.getMachinesForNetwork(networkId);

    expect(machines.length, 1);
    expect(machines.first.id, machineId);
    expect(machines.first.networkId, networkId);
    expect(machines.first.name, 'Test Machine');
    expect(machines.first.tailscaleIp, '100.100.100.100');
    expect(machines.first.macAddress, 'AA:BB:CC:DD:EE:FF');
    expect(machines.first.status, MachineStatus.online);
  });
}
