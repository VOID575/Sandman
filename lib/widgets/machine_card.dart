import 'package:flutter/material.dart';
import '../api/wol_manager.dart';
import '../constants/api_constants.dart';
import '../database/app_database.dart';
import '../models/machine.dart';
import '../models/wol_payload.dart';
import '../theme/app_theme.dart';
import 'status_badges.dart';

class MachineCard extends StatefulWidget {
  final MachineData machine;
  final NetworkData network;

  final WolManager? wolManager;
  final AppDatabase? appDatabase;

  const MachineCard({
    super.key,
    required this.machine,
    required this.network,
    this.wolManager,
    this.appDatabase,
  });

  @override
  State<MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  late final WolManager _wolManager = widget.wolManager ?? WolManager();
  late final AppDatabase _appDatabase =
      widget.appDatabase ?? AppDatabase.instance;

  late MachineData _currentMachine = widget.machine;
  bool _isLoading = false;

  @override
  void didUpdateWidget(MachineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machine != widget.machine) {
      _currentMachine = widget.machine;
    }
  }

  Future<void> _handlePowerAction() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = WolPayload(
        _currentMachine.macAddress,
        widget.network.broadcastAddress,
        widget.network.routerIp,
      );

      final isOffline = _currentMachine.status == MachineStatus.offline;

      final response = isOffline
          ? await _wolManager.sendWolSignal(ApiConstants.http, payload)
          : await _wolManager.sendShutdownSignal(ApiConstants.http, payload);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline ? 'Wake signal sent...' : 'Shutdown signal sent...',
            ),
          ),
        );

        // Update local DB status (wakingUp or shuttingDown)
        final newStatus = isOffline
            ? MachineStatus.wakingUp
            : MachineStatus.shuttingDown;

        final updatedMachine = _currentMachine.copyWith(status: newStatus);
        await _appDatabase.machineDao.updateMachine(updatedMachine);

        if (mounted) {
          setState(() {
            _currentMachine = updatedMachine;
          });
        }
      } else {
        // API Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Could not reach router'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.computer, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentMachine.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                MachineStatusBadge(status: _currentMachine.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context,
                        icon: Icons.network_check,
                        label: 'IP Address',
                        value: _currentMachine.tailscaleIp,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        icon: Icons.memory,
                        label: 'MAC Address',
                        value: _currentMachine.macAddress,
                      ),
                    ],
                  ),
                ),
                _buildPowerButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerButton(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isOffline = _currentMachine.status == MachineStatus.offline;
    final isTransitioning =
        _currentMachine.status == MachineStatus.wakingUp ||
        _currentMachine.status == MachineStatus.shuttingDown;

    if (isTransitioning) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: _handlePowerAction,
      icon: Icon(
        Icons.power_settings_new,
        color: isOffline
            ? AppStatusColors.online
            : AppStatusColors.shuttingDown,
      ),
      tooltip: isOffline ? 'Wake up' : 'Shut down',
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace', // Often good for IPs and MACs
          ),
        ),
      ],
    );
  }
}
