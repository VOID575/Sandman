import 'package:sandman/api/wol_manager.dart';
import 'package:sandman/constants/api_constants.dart';
import 'package:sandman/database/app_database.dart';
import 'package:sandman/models/machine.dart';

/// Snapshot returned after polling a network and its machines.
class NetworkStatusSnapshot {
  final NetworkData network;
  final List<MachineData> machines;

  const NetworkStatusSnapshot({required this.network, required this.machines});
}

class _MachineCheckResult {
  final int machineId;
  final bool gatewayResponded;
  final MachineStatus? reportedStatus;

  const _MachineCheckResult({
    required this.machineId,
    required this.gatewayResponded,
    required this.reportedStatus,
  });
}

/// Polls the gateway Go API to detect gateway reachability and machine states,
/// and persists updated statuses into the local Drift database.
class NetworkStatusService {
  final WolManager _wolManager;
  final AppDatabase _appDatabase;
  final String httpProtocol;
  final Duration transitionTimeout;
  final DateTime Function() _now;

  final Map<int, DateTime> _transitionStartedAt = {};

  NetworkStatusService({
    WolManager? wolManager,
    AppDatabase? appDatabase,
    this.httpProtocol = ApiConstants.http,
    this.transitionTimeout = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _wolManager = wolManager ?? WolManager(),
       _appDatabase = appDatabase ?? AppDatabase.instance,
       _now = now ?? DateTime.now;

  /// Records when a user-initiated wake or shutdown transition began so short
  /// polling cycles do not immediately revert the transitional badge.
  void markTransitionStarted(int machineId) {
    _transitionStartedAt[machineId] = _now();
  }

  /// Queries the gateway API for all machines in [network], resolves transitions,
  /// and persists machine and network statuses to the local database.
  Future<NetworkStatusSnapshot> refreshNetworkStatus(
    NetworkData network,
  ) async {
    final initialMachines = await _appDatabase.machineDao.getMachinesForNetwork(
      network.id,
    );

    if (initialMachines.isEmpty) {
      final isGatewayRunning = await _wolManager.isGatewayReachable(
        httpProtocol,
        network.gatewayIp,
        network.gatewayPort,
      );
      return _persistNetworkSummary(
        network,
        isGatewayRunning: isGatewayRunning,
        machines: const [],
      );
    }

    final results = await Future.wait(
      initialMachines.map((machine) => _checkSingleMachine(network, machine)),
    );

    final isGatewayRunning = results.any((result) => result.gatewayResponded);
    final resultsById = {for (final r in results) r.machineId: r};

    // Re-read from DB so machines deleted or toggled mid-flight are respected.
    final latestMachines = await _appDatabase.machineDao.getMachinesForNetwork(
      network.id,
    );
    final latestIds = latestMachines.map((m) => m.id).toSet();
    _transitionStartedAt.removeWhere((id, _) => !latestIds.contains(id));

    final updatedMachines = <MachineData>[];
    for (final machine in latestMachines) {
      final checkResult = resultsById[machine.id];
      final reportedStatus = checkResult?.reportedStatus;

      if (reportedStatus == null) {
        updatedMachines.add(machine);
        continue;
      }

      final nextStatus = _resolveMachineStatus(machine, reportedStatus);
      if (nextStatus != machine.status) {
        await _appDatabase.machineDao.updateMachineStatus(
          machine.id,
          nextStatus,
        );
        updatedMachines.add(machine.copyWith(status: nextStatus));
      } else {
        updatedMachines.add(machine);
      }
    }

    return _persistNetworkSummary(
      network,
      isGatewayRunning: isGatewayRunning,
      machines: updatedMachines,
    );
  }

  /// Recomputes and persists [runningMachines] from the given [machines] list.
  Future<NetworkData> syncRunningMachinesCount(
    NetworkData network,
    List<MachineData> machines,
  ) async {
    final snapshot = await _persistNetworkSummary(
      network,
      isGatewayRunning: network.isGatewayRunning,
      machines: machines,
    );
    return snapshot.network;
  }

  Future<NetworkStatusSnapshot> _persistNetworkSummary(
    NetworkData network, {
    required bool isGatewayRunning,
    required List<MachineData> machines,
  }) async {
    final runningMachines = machines
        .where((machine) => machine.status == MachineStatus.online)
        .length;

    await _appDatabase.networkDao.updateNetworkStatus(
      networkId: network.id,
      isGatewayRunning: isGatewayRunning,
      runningMachines: runningMachines,
    );

    return NetworkStatusSnapshot(
      network: network.copyWith(
        isGatewayRunning: isGatewayRunning,
        runningMachines: runningMachines,
      ),
      machines: machines,
    );
  }

  Future<_MachineCheckResult> _checkSingleMachine(
    NetworkData network,
    MachineData machine,
  ) async {
    try {
      final response = await _wolManager.getMachineStatus(
        httpProtocol,
        network.gatewayIp,
        network.gatewayPort,
        machine.tailscaleIp,
      );
      return _MachineCheckResult(
        machineId: machine.id,
        gatewayResponded: response.statusCode < 500,
        reportedStatus: response.isSuccess ? response.status : null,
      );
    } catch (_) {
      return _MachineCheckResult(
        machineId: machine.id,
        gatewayResponded: false,
        reportedStatus: null,
      );
    }
  }

  MachineStatus _resolveMachineStatus(
    MachineData machine,
    MachineStatus reportedStatus,
  ) {
    final targetStatus = switch (machine.status) {
      MachineStatus.wakingUp => MachineStatus.online,
      MachineStatus.shuttingDown => MachineStatus.offline,
      _ => null,
    };

    if (targetStatus == null) {
      _transitionStartedAt.remove(machine.id);
      return reportedStatus;
    }

    if (reportedStatus == targetStatus) {
      _transitionStartedAt.remove(machine.id);
      return reportedStatus;
    }

    // Keep transitional state during the grace period so short polls do not
    // cancel "Waking Up" / "Shutting Down" before the OS finishes transitioning.
    final startedAt = _transitionStartedAt.putIfAbsent(machine.id, _now);
    if (_now().difference(startedAt) >= transitionTimeout) {
      _transitionStartedAt.remove(machine.id);
      return reportedStatus;
    }

    return machine.status;
  }
}
