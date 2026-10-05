import 'package:flutter/material.dart';
import '../database/app_database.dart';
import 'status_badges.dart';

class NetworkCard extends StatelessWidget {
  final NetworkData network;
  final VoidCallback? onTap;

  const NetworkCard({super.key, required this.network, this.onTap});

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
      clipBehavior:
          Clip.antiAlias, // Ensures the InkWell splash stays inside the border
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Text(
                        network.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  RouterStatusBadge(isRunning: network.isRouterRunning),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                network.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.computer,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<List<MachineData>>(
                    future: AppDatabase.instance.machineDao
                        .getMachinesForNetwork(network.id),
                    builder: (context, snapshot) {
                      final totalMachines = snapshot.data?.length ?? 0;
                      return Text(
                        '${network.runningMachines} / $totalMachines Machines running',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
