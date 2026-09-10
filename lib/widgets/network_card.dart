import 'package:flutter/material.dart';
import '../models/network.dart';
import '../theme/app_theme.dart';

class NetworkCard extends StatelessWidget {
  final Network network;

  const NetworkCard({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: 1,
        ),
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
                  child: Text(
                    network.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                _RouterStatusBadge(isRunning: network.isRouterRunning),
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
                Text(
                  '${network.runningMachines} / ${network.totalMachines} Machines running',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouterStatusBadge extends StatelessWidget {
  final bool isRunning;

  const _RouterStatusBadge({required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isRunning ? AppStatusColors.online : AppStatusColors.offline;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isRunning ? 'Router Online' : 'Router Offline',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
