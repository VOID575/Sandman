import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sandman/api/wol_manager.dart';
import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/machine.dart';
import 'package:sandman/services/network_status_service.dart';

void main() {
  late AppDatabase database;
  late NetworkData testNetwork;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final networkId = await database.networkDao.insertNetwork(
      NetworkCompanion.insert(
        name: 'Home Network',
        description: 'Home lab',
        gatewayIp: '100.100.100.1',
        gatewayPort: 8080,
      ),
    );
    testNetwork = (await database.networkDao.getNetworkById(networkId))!;
  });

  tearDown(() async {
    await database.close();
  });

  Future<MachineData> insertMachine({
    required String name,
    required String ip,
    required MachineStatus status,
  }) async {
    final id = await database.machineDao.insertMachine(
      MachineCompanion.insert(
        networkId: testNetwork.id,
        name: name,
        tailscaleIp: ip,
        macAddress: 'AA:BB:CC:DD:EE:01',
        status: drift.Value(status),
      ),
    );
    return (await database.machineDao.getMachinesForNetwork(
      testNetwork.id,
    )).firstWhere((m) => m.id == id);
  }

  group('NetworkStatusService', () {
    test(
      'updates machine statuses, isGatewayRunning, and runningMachines in DB',
      () async {
        final pc1 = await insertMachine(
          name: 'PC1',
          ip: '100.64.0.10',
          status: MachineStatus.offline,
        );
        final pc2 = await insertMachine(
          name: 'PC2',
          ip: '100.64.0.11',
          status: MachineStatus.online,
        );

        final wolManager = WolManager(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/100.64.0.10')) {
              return http.Response('{"status": "online"}', 200);
            }
            if (request.url.path.endsWith('/100.64.0.11')) {
              return http.Response('{"status": "offline"}', 200);
            }
            return http.Response('', 404);
          }),
        );

        final service = NetworkStatusService(
          wolManager: wolManager,
          appDatabase: database,
        );

        final snapshot = await service.refreshNetworkStatus(testNetwork);

        expect(snapshot.network.isGatewayRunning, isTrue);
        expect(snapshot.network.runningMachines, 1);

        final updatedPc1 = snapshot.machines.firstWhere((m) => m.id == pc1.id);
        final updatedPc2 = snapshot.machines.firstWhere((m) => m.id == pc2.id);
        expect(updatedPc1.status, MachineStatus.online);
        expect(updatedPc2.status, MachineStatus.offline);

        final persistedNet = await database.networkDao.getNetworkById(
          testNetwork.id,
        );
        expect(persistedNet!.isGatewayRunning, isTrue);
        expect(persistedNet.runningMachines, 1);
      },
    );

    test(
      'empty network checks gateway reachability and persists runningMachines = 0',
      () async {
        final wolManager = WolManager(
          client: MockClient((request) async {
            expect(request.url.path, '/status');
            return http.Response('', 200);
          }),
        );

        final service = NetworkStatusService(
          wolManager: wolManager,
          appDatabase: database,
        );

        final snapshot = await service.refreshNetworkStatus(testNetwork);

        expect(snapshot.network.isGatewayRunning, isTrue);
        expect(snapshot.network.runningMachines, 0);
        expect(snapshot.machines, isEmpty);
      },
    );

    test(
      'gateway unreachable sets isGatewayRunning = false and preserves last known machine statuses',
      () async {
        await insertMachine(
          name: 'Server',
          ip: '100.64.0.20',
          status: MachineStatus.online,
        );

        final wolManager = WolManager(
          client: MockClient(
            (_) async => throw http.ClientException('Timeout'),
          ),
        );

        final service = NetworkStatusService(
          wolManager: wolManager,
          appDatabase: database,
        );

        final snapshot = await service.refreshNetworkStatus(testNetwork);

        expect(snapshot.network.isGatewayRunning, isFalse);
        expect(snapshot.network.runningMachines, 1);
        expect(snapshot.machines.first.status, MachineStatus.online);
      },
    );

    test(
      'keeps wakingUp and shuttingDown during grace period and resolves on target or timeout',
      () async {
        var fakeNow = DateTime(2026, 11, 15, 12, 0, 0);
        final waking = await insertMachine(
          name: 'WakingPC',
          ip: '100.64.0.30',
          status: MachineStatus.wakingUp,
        );
        final shutting = await insertMachine(
          name: 'ShuttingPC',
          ip: '100.64.0.31',
          status: MachineStatus.shuttingDown,
        );

        var wakingReply = 'offline';
        var shuttingReply = 'online';

        final wolManager = WolManager(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/100.64.0.30')) {
              return http.Response('{"status": "$wakingReply"}', 200);
            }
            return http.Response('{"status": "$shuttingReply"}', 200);
          }),
        );

        final service = NetworkStatusService(
          wolManager: wolManager,
          appDatabase: database,
          transitionTimeout: const Duration(seconds: 60),
          now: () => fakeNow,
        );

        service.markTransitionStarted(waking.id);
        service.markTransitionStarted(shutting.id);

        // At +20s, machine responses haven't flipped yet -> keep transitional states
        fakeNow = fakeNow.add(const Duration(seconds: 20));
        var snapshot = await service.refreshNetworkStatus(testNetwork);
        expect(
          snapshot.machines.firstWhere((m) => m.id == waking.id).status,
          MachineStatus.wakingUp,
        );
        expect(
          snapshot.machines.firstWhere((m) => m.id == shutting.id).status,
          MachineStatus.shuttingDown,
        );

        // ShuttingPC finishes shutting down -> transitions immediately to offline
        shuttingReply = 'offline';
        fakeNow = fakeNow.add(const Duration(seconds: 10));
        snapshot = await service.refreshNetworkStatus(testNetwork);
        expect(
          snapshot.machines.firstWhere((m) => m.id == shutting.id).status,
          MachineStatus.offline,
        );
        expect(
          snapshot.machines.firstWhere((m) => m.id == waking.id).status,
          MachineStatus.wakingUp,
        );

        // At +60s total, WakingPC still replies offline -> timeout falls back to offline
        fakeNow = fakeNow.add(const Duration(seconds: 30));
        snapshot = await service.refreshNetworkStatus(testNetwork);
        expect(
          snapshot.machines.firstWhere((m) => m.id == waking.id).status,
          MachineStatus.offline,
        );
      },
    );

    test(
      'does not resurrect a machine deleted while status polling is in flight',
      () async {
        final pc1 = await insertMachine(
          name: 'PC1',
          ip: '100.64.0.40',
          status: MachineStatus.offline,
        );
        final pc2 = await insertMachine(
          name: 'PC2',
          ip: '100.64.0.41',
          status: MachineStatus.offline,
        );

        final pc1Completer = Completer<http.Response>();
        final wolManager = WolManager(
          client: MockClient((request) {
            if (request.url.path.endsWith('/100.64.0.40')) {
              return pc1Completer.future;
            }
            return Future.value(http.Response('{"status": "online"}', 200));
          }),
        );

        final service = NetworkStatusService(
          wolManager: wolManager,
          appDatabase: database,
        );

        final refreshFuture = service.refreshNetworkStatus(testNetwork);

        // Delete PC1 before its HTTP response arrives
        await database.machineDao.deleteMachine(pc1.toCompanion(false));
        pc1Completer.complete(http.Response('{"status": "online"}', 200));

        final snapshot = await refreshFuture;
        expect(snapshot.machines.map((m) => m.id), [pc2.id]);
        expect(snapshot.machines.single.status, MachineStatus.online);
        expect(snapshot.network.runningMachines, 1);
      },
    );
  });
}
