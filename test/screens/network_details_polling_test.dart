import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sandman/api/wol_manager.dart';
import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/machine.dart';
import 'package:sandman/screens/home_page.dart';
import 'package:sandman/screens/network_details_screen.dart';

void main() {
  late AppDatabase testDatabase;
  late NetworkData testNetwork;

  setUp(() async {
    testDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setTestInstance(testDatabase);

    final netId = await testDatabase.networkDao.insertNetwork(
      NetworkCompanion.insert(
        name: 'Lab Network',
        description: 'Test Lab',
        gatewayIp: '100.100.100.1',
        gatewayPort: 8080,
      ),
    );
    testNetwork = (await testDatabase.networkDao.getNetworkById(netId))!;

    await testDatabase.machineDao.insertMachine(
      MachineCompanion.insert(
        networkId: testNetwork.id,
        name: 'Desktop PC',
        tailscaleIp: '100.64.0.10',
        macAddress: 'AA:BB:CC:DD:EE:01',
        status: const drift.Value(MachineStatus.offline),
      ),
    );
  });

  tearDown(() async {
    await testDatabase.close();
  });

  group('NetworkDetailsScreen status detection & polling', () {
    testWidgets(
      'fetches status on open, polls every 10s, and supports pull-to-refresh',
      (WidgetTester tester) async {
        var pollCount = 0;
        var remoteStatus = 'offline';

        final wolManager = WolManager(
          client: MockClient((request) async {
            if (request.method == 'GET' &&
                request.url.path == '/status/100.64.0.10') {
              pollCount++;
              return http.Response('{"status": "$remoteStatus"}', 200);
            }
            if (request.method == 'POST' && request.url.path == '/wakeonlan') {
              return http.Response('{"message": "Magic packet sent"}', 200);
            }
            return http.Response('{"error": "not found"}', 404);
          }),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: NetworkDetailsScreen(
              network: testNetwork,
              wolManager: wolManager,
              appDatabase: testDatabase,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initial load checked gateway and machine status immediately
        expect(pollCount, 1);
        expect(find.text('Gateway Online'), findsOneWidget);
        expect(find.text('Offline'), findsOneWidget);

        // User taps Wake -> UI enters Waking Up
        await tester.tap(find.byIcon(Icons.power_settings_new));
        await tester.pump();
        expect(find.text('Waking Up'), findsOneWidget);

        // 10s poll #1 while machine is still booting -> remains Waking Up
        // (use pump() instead of pumpAndSettle() because Waking Up renders a spinning CircularProgressIndicator)
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();
        expect(pollCount, 2);
        expect(find.text('Waking Up'), findsOneWidget);

        // Remote machine finishes booting -> next 10s poll turns it Online
        remoteStatus = 'online';
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
        expect(pollCount, 3);
        expect(find.text('Online'), findsOneWidget);

        // Manual pull-to-refresh detects remote shutdown -> Offline
        remoteStatus = 'offline';
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();
        expect(pollCount, greaterThanOrEqualTo(4));
        expect(find.text('Offline'), findsOneWidget);
      },
    );

    testWidgets(
      'HomePage reflects updated gateway status and runningMachines when returning from NetworkDetailsScreen',
      (WidgetTester tester) async {
        final wolManager = WolManager(
          client: MockClient((request) async {
            if (request.method == 'GET' &&
                request.url.path == '/status/100.64.0.10') {
              return http.Response('{"status": "online"}', 200);
            }
            return http.Response('', 404);
          }),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: HomePage(
              title: 'Sandman',
              isDarkMode: false,
              onThemeChanged: (_) {},
              wolManager: wolManager,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gateway Offline'), findsOneWidget);
        expect(find.text('0 / 1 Machines running'), findsOneWidget);

        // Tap into Lab Network -> initial poll detects gateway and machine online
        await tester.tap(find.text('Lab Network'));
        await tester.pumpAndSettle();

        expect(find.text('Gateway Online'), findsOneWidget);
        expect(find.text('Online'), findsOneWidget);

        // Return to HomePage via Back button -> HomePage refreshes NetworkCard
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.text('Gateway Online'), findsOneWidget);
        expect(find.text('1 / 1 Machines running'), findsOneWidget);
      },
    );
  });
}
