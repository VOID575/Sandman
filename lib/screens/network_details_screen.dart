import 'dart:math';
import 'package:flutter/material.dart';
import '../models/network.dart';
import '../models/machine.dart';
import '../widgets/status_badges.dart';
import '../widgets/machine_card.dart';

class NetworkDetailsScreen extends StatefulWidget {
  final Network network;

  const NetworkDetailsScreen({
    super.key,
    required this.network,
  });

  @override
  State<NetworkDetailsScreen> createState() => _NetworkDetailsScreenState();
}

class _NetworkDetailsScreenState extends State<NetworkDetailsScreen> {
  
  Future<void> _refreshMachines() async {
    // Simulate a network request
    await Future.delayed(const Duration(seconds: 1));
    
    // Randomly update some statuses to demonstrate the UI
    setState(() {
      final random = Random();
      for (var machine in widget.network.machines) {
        // Randomly transition statuses for the sake of the dummy implementation
        int r = random.nextInt(100);
        if (machine.status == MachineStatus.offline) {
          if (r < 30) machine.status = MachineStatus.wakingUp;
        } else if (machine.status == MachineStatus.wakingUp) {
          if (r < 80) machine.status = MachineStatus.online;
        } else {
          if (r < 10) machine.status = MachineStatus.offline;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.network.name),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMachines,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Router Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        RouterStatusBadge(isRunning: widget.network.isRouterRunning),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.network.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Machines (${widget.network.totalMachines})',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull down to refresh statuses',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.network.machines.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No machines found in this network.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final machine = widget.network.machines[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.network.machines.length - 1 ? 24.0 : 0,
                      ),
                      child: MachineCard(machine: machine),
                    );
                  },
                  childCount: widget.network.machines.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
