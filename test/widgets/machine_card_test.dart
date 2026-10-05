import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';

import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/machine.dart';
import 'package:sandman/api/wol_manager.dart';
import 'package:sandman/widgets/machine_card.dart';
import 'package:sandman/theme/app_theme.dart';

void main() {
  late AppDatabase database;
  late NetworkData testNetwork;

  setUp(() async {
    // Setup in-memory drift database to capture status updates without hitting a real file
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final networkId = await database.networkDao.insertNetwork(
      NetworkCompanion.insert(
        name: 'Test Network',
        description: 'Test Desc',
        routerIp: '192.168.1.1',
        routerPort: 9,
        broadcastAddress: const drift.Value('255.255.255.255'),
      ),
    );
    final networks = await database.networkDao.getAllNetworks();
    testNetwork = networks.firstWhere((n) => n.id == networkId);
  });

  tearDown(() async {
    await database.close();
  });

  Future<MachineData> insertMachine(MachineStatus status) async {
    final machineId = await database.machineDao.insertMachine(
      MachineCompanion.insert(
        networkId: testNetwork.id,
        name: 'Test PC',
        tailscaleIp: '100.100.100.100',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        status: drift.Value(status),
      ),
    );
    final machines = await database.machineDao.getMachinesForNetwork(
      testNetwork.id,
    );
    return machines.firstWhere((m) => m.id == machineId);
  }

  Widget createWidgetUnderTest(MachineData machine, WolManager wolManager) {
    return MaterialApp(
      home: Scaffold(
        body: MachineCard(
          machine: machine,
          network: testNetwork,
          wolManager: wolManager,
          appDatabase: database,
        ),
      ),
    );
  }

  group('MachineCard Dynamic Power Button Integration Tests', () {
    testWidgets('Wake Action (Success) should update status to wakingUp', (
      WidgetTester tester,
    ) async {
      // Arrange
      final machine = await insertMachine(MachineStatus.offline);
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/wakeonlan'));
        return completer.future;
      });
      final wolManager = WolManager(client: mockClient);

      await tester.pumpWidget(createWidgetUnderTest(machine, wolManager));

      // Assert initial offline state (Wake button)
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.icon, Icons.power_settings_new);
      expect(icon.color, AppStatusColors.online);

      // Act
      await tester.tap(find.byType(IconButton));
      await tester.pump(); // Trigger setState for loading spinner

      // Assert Loading Spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve the API call
      completer.complete(
        http.Response('{"message": "Magic packet sent successfully"}', 200),
      );

      await tester.pump(); // Allow setState to process

      // Assert SnackBar Feedback
      expect(find.text('Wake signal sent...'), findsOneWidget);

      // Assert DB State
      final updatedMachines = await database.machineDao.getMachinesForNetwork(
        testNetwork.id,
      );
      expect(updatedMachines.first.status, MachineStatus.wakingUp);
    });

    testWidgets(
      'Shutdown Action (Success) should transition through loading state, show success snackbar, and update DB status always',
      (WidgetTester tester) async {
        // Arrange
        final machine = await insertMachine(MachineStatus.online);
        final completer = Completer<http.Response>();

        final mockClient = MockClient((request) async {
          expect(request.url.path, contains('/shutdown'));
          return completer.future;
        });
        final wolManager = WolManager(client: mockClient);

        await tester.pumpWidget(createWidgetUnderTest(machine, wolManager));

        // Assert initial online state (Shutdown button)
        final iconButton = tester.widget<IconButton>(find.byType(IconButton));
        final icon = iconButton.icon as Icon;
        expect(icon.color, AppStatusColors.shuttingDown);

        // Act
        await tester.tap(find.byType(IconButton));
        await tester.pump(); // Trigger loading

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(
          http.Response(
            '{"message": "Shutdown signal sent successfully"}',
            200,
          ),
        );

        await tester.pump(); // Resolve API

        // Assert SnackBar
        expect(find.text('Shutdown signal sent...'), findsOneWidget);

        // Assert DB State
        final updatedMachines = await database.machineDao.getMachinesForNetwork(
          testNetwork.id,
        );
        expect(updatedMachines.first.status, MachineStatus.shuttingDown);
      },
    );

    testWidgets(
      'Error Handling (API Failure) should show error and revert UI',
      (WidgetTester tester) async {
        // Arrange
        final machine = await insertMachine(MachineStatus.offline);
        final completer = Completer<http.Response>();

        final mockClient = MockClient((request) async {
          return completer.future;
        });
        final wolManager = WolManager(client: mockClient);

        await tester.pumpWidget(createWidgetUnderTest(machine, wolManager));

        // Act
        await tester.tap(find.byType(IconButton));
        await tester.pump(); // Show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(http.Response('{"message": "Server Error"}', 500));

        await tester.pump(); // Resolve API error

        // Assert Error SnackBar
        expect(find.textContaining('Failed: Server Error'), findsOneWidget);

        // Assert Reverted to original Button (No spinner anymore)
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(IconButton), findsOneWidget);

        // Assert DB State remained offline
        final updatedMachines = await database.machineDao.getMachinesForNetwork(
          testNetwork.id,
        );
        expect(updatedMachines.first.status, MachineStatus.offline);
      },
    );

    testWidgets('UI Protection (Spam-clicking) should only send one request', (
      WidgetTester tester,
    ) async {
      // Arrange
      int requestCount = 0;
      final machine = await insertMachine(MachineStatus.offline);
      final completer = Completer<http.Response>();

      final mockClient = MockClient((request) async {
        requestCount++;
        return completer.future;
      });
      final wolManager = WolManager(client: mockClient);

      await tester.pumpWidget(createWidgetUnderTest(machine, wolManager));

      // Act - spam click rapidly before pumping frames
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));

      completer.complete(http.Response('{"message": "ok"}', 200));
      await tester.pump(); // We just wait for the single future to finish

      // Assert that despite 5 taps, the _isLoading guard prevented multiple calls
      expect(requestCount, 1);
    });

    testWidgets('Background Polling Integration should dynamically change UI', (
      WidgetTester tester,
    ) async {
      // Arrange
      final machineWaking = await insertMachine(MachineStatus.wakingUp);
      final wolManager = WolManager(
        client: MockClient((r) async => http.Response('', 200)),
      );

      await tester.pumpWidget(createWidgetUnderTest(machineWaking, wolManager));

      // Assert initially in transitioning state (loading spinner)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Act - Simulate background poll returning the machine as online
      final machineOnline = machineWaking.copyWith(
        status: MachineStatus.online,
      );

      // Re-pump widget with the new data
      await tester.pumpWidget(createWidgetUnderTest(machineOnline, wolManager));

      // Assert UI updated to "Shutdown" (red) visual automatically
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final icon = iconButton.icon as Icon;
      expect(icon.color, AppStatusColors.shuttingDown);
    });
  });
}
