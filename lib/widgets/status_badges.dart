import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/machine.dart';

class RouterStatusBadge extends StatelessWidget {
  final bool isRunning;

  const RouterStatusBadge({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isRunning ? AppStatusColors.online : AppStatusColors.offline;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
          const SizedBox(width: 8),
          Text(
            isRunning ? 'Router Online' : 'Router Offline',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class MachineStatusBadge extends StatelessWidget {
  final MachineStatus status;

  const MachineStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    late final Color color;
    late final String label;
    
    switch (status) {
      case MachineStatus.online:
        color = AppStatusColors.online;
        label = 'Online';
        break;
      case MachineStatus.offline:
        color = AppStatusColors.offline;
        label = 'Offline';
        break;
      case MachineStatus.wakingUp:
        color = AppStatusColors.wakingUp;
        label = 'Waking Up';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              boxShadow: [
                if (status == MachineStatus.wakingUp || status == MachineStatus.online)
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
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
