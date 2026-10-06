import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';

import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/machine.dart';
import 'package:sandman/screens/home_page.dart';
import 'package:sandman/screens/network_details_screen.dart';

void main() {
  late AppDatabase testDatabase;

  setUp(() async {
    // 1. Arrange global dependencies
    testDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setTestInstance(testDatabase);

    // 2. Insert dummy data for tests
    final homeNetId = await testDatabase.networkDao.insertNetwork(
      NetworkCompanion.insert(
        name: 'Home Network',
        description: 'My home network',
        routerIp: '192.168.1.1',
        routerPort: 9,
        broadcastAddress: const drift.Value('255.255.255.255'),
      ),
    );

    await testDatabase.networkDao.insertNetwork(
      NetworkCompanion.insert(
        name: 'Office Network',
        description: 'My office network',
        routerIp: '10.0.0.1',
        routerPort: 9,
        broadcastAddress: const drift.Value('255.255.255.255'),
      ),
    );

    await testDatabase.machineDao.insertMachine(
      MachineCompanion.insert(
        networkId: homeNetId,
        name: 'Machine A',
        tailscaleIp: '100.100.100.1',
        macAddress: 'AA:BB:CC:DD:EE:01',
        status: const drift.Value(MachineStatus.offline),
      ),
    );

    await testDatabase.machineDao.insertMachine(
      MachineCompanion.insert(
        networkId: homeNetId,
        name: 'Machine B',
        tailscaleIp: '100.100.100.2',
        macAddress: 'AA:BB:CC:DD:EE:02',
        status: const drift.Value(MachineStatus.offline),
      ),
    );
  });

  tearDown(() async {
    await testDatabase.close();
  });

  Future<void> pumpHomePage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(
          title: 'Sandman Test',
          isDarkMode: false,
          onThemeChanged: _dummyThemeChange,
        ),
      ),
    );
    await tester.pumpAndSettle(); // Wait for data loading
  }

  group('Machine Deletion Integration Tests', () {
    testWidgets(
      'Machine Deletion Should Not Delete When Cancel Pop-Up Button Is Taped',
      (WidgetTester tester) async {
        // Arrange
        await pumpHomePage(tester);
        await tester.tap(find.text('Home Network'));
        await tester.pumpAndSettle();

        expect(find.byType(NetworkDetailsScreen), findsOneWidget);
        expect(find.text('Machine A'), findsOneWidget);

        // Act (Swipe to delete)
        await tester.drag(find.text('Machine A'), const Offset(-500.0, 0.0));
        await tester.pumpAndSettle();

        // Assert Dialog
        expect(find.text('Delete Machine?'), findsOneWidget);
        expect(
          find.text(
            "Are you sure you want to remove 'Machine A' from this network?",
          ),
          findsOneWidget,
        );

        // Act (Cancel)
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert Machine A still present
        expect(find.text('Machine A'), findsOneWidget);
        expect(find.text('Delete Machine?'), findsNothing);
      },
    );

    testWidgets(
      'Machine Deletion Should Delete When Confirm Pop-Up Button Is Taped',
      (WidgetTester tester) async {
        // Arrange
        await pumpHomePage(tester);
        await tester.tap(find.text('Home Network'));
        await tester.pumpAndSettle();

        expect(find.byType(NetworkDetailsScreen), findsOneWidget);
        expect(find.text('Machine A'), findsOneWidget);

        // Act (Swipe to delete)
        await tester.drag(find.text('Machine A'), const Offset(-500.0, 0.0));
        await tester.pumpAndSettle();

        // Assert Dialog
        expect(find.text('Delete Machine?'), findsOneWidget);
        expect(
          find.text(
            "Are you sure you want to remove 'Machine A' from this network?",
          ),
          findsOneWidget,
        );

        // Act (Swipe and Confirm)
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle(); // Allow animation to finish

        // Assert Machine A is instantly removed from UI
        expect(find.text('Machine A'), findsNothing);
        expect(
          find.text("Machine 'Machine A' deleted."),
          findsOneWidget,
        ); // SnackBar

        // Assert Machine A is actually removed from DB
        final machinesInDb = await testDatabase.machineDao.getAllMachines();
        expect(machinesInDb.where((m) => m.name == 'Machine A'), isEmpty);
      },
    );

    testWidgets(
      'Machine Deletion (Undo action) Should Cancel Machine Deletion',
      (WidgetTester tester) async {
        // Arrange
        await pumpHomePage(tester);
        await tester.tap(find.text('Home Network'));
        await tester.pumpAndSettle();

        expect(find.text('Machine B'), findsOneWidget);

        // Act (Delete Machine B)
        await tester.drag(find.text('Machine B'), const Offset(-500.0, 0.0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Assert it's gone
        expect(find.text('Machine B'), findsNothing);
        expect(find.text("Machine 'Machine B' deleted."), findsOneWidget);

        // Act (Undo)
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();

        // Assert Machine B reappears in UI
        expect(find.text('Machine B'), findsOneWidget);

        // Assert Machine B is back in DB
        final machinesInDb = await testDatabase.machineDao.getAllMachines();
        expect(machinesInDb.where((m) => m.name == 'Machine B'), isNotEmpty);
      },
    );
  });

  group('Network Deletion Integration Tests', () {
    testWidgets(
      'Network Deletion Should Not Delete Network When Sentence Typed Is Wrong',
      (WidgetTester tester) async {
        // Arrange
        await pumpHomePage(tester);
        await tester.tap(find.text('Home Network'));
        await tester.pumpAndSettle();

        // Act (Tap Delete Network)
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Assert Dialog
        expect(find.text('Delete Network?'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to delete this network? All associated machines will also be permanently removed. This action cannot be undone.',
          ),
          findsOneWidget,
        );

        final deleteButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Delete'),
        );
        expect(deleteButton.onPressed, isNull); // Disabled by default

        // Act (Type wrong sentence)
        await tester.enterText(find.byType(TextField), 'delete Home Network');
        await tester.pumpAndSettle();

        // Assert still disabled
        final deleteButtonWrong = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Delete'),
        );
        expect(deleteButtonWrong.onPressed, isNull);

        // Act (Cancel)
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert Dialog closed, Network still there
        expect(find.text('Delete Network?'), findsNothing);
        final networksInDb = await testDatabase.networkDao.getAllNetworks();
        expect(networksInDb.where((n) => n.name == 'Home Network'), isNotEmpty);
      },
    );

    testWidgets(
      'Network Deletion Should Not Delete Network When Cancel Pop-Up Button Is Taped',
      (WidgetTester tester) async {
        // Arrange
        await pumpHomePage(tester);
        await tester.tap(find.text('Home Network'));
        await tester.pumpAndSettle();

        // Act (Tap Delete Network)
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert Dialog closed, Network still there
        expect(find.text('Delete Network?'), findsNothing);
        final networksInDb = await testDatabase.networkDao.getAllNetworks();
        expect(networksInDb.where((n) => n.name == 'Home Network'), isNotEmpty);
      },
    );

    testWidgets(
      'Network Deletion Should Delete Network Successfully When The Right Text Is Typed',
      (WidgetTester tester) async {
        // Arrange
        await pumpHomePage(tester);
        await tester.tap(find.text('Home Network'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'I want to delete the network Home Network',
        );
        await tester.pumpAndSettle();

        // Assert button enabled
        final deleteButtonValid = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Delete'),
        );
        expect(deleteButtonValid.onPressed, isNotNull);

        // Act
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
        await tester.pumpAndSettle();

        // Assert automatically navigated back to HomePage
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(NetworkDetailsScreen), findsNothing);

        // Assert SnackBar
        expect(
          find.text("Network 'Home Network' successfully deleted."),
          findsOneWidget,
        );

        // Assert Network is no longer in the list (UI)
        expect(find.text('Home Network'), findsNothing);
        expect(
          find.text('Office Network'),
          findsOneWidget,
        ); // Make sure the other is still there

        // Assert Cascade Delete in Database
        final networksInDb = await testDatabase.networkDao.getAllNetworks();
        expect(networksInDb.where((n) => n.name == 'Home Network'), isEmpty);

        final machinesInDb = await testDatabase.machineDao.getAllMachines();
        // Machine A and Machine B were tied to Home Network, they should be gone
        expect(machinesInDb, isEmpty);
      },
    );
  });
}

void _dummyThemeChange(bool val) {}
