import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../widgets/status_badges.dart';
import '../widgets/machine_card.dart';

class NetworkDetailsScreen extends StatefulWidget {
  final NetworkData network;

  const NetworkDetailsScreen({super.key, required this.network});

  @override
  State<NetworkDetailsScreen> createState() => _NetworkDetailsScreenState();
}

class _NetworkDetailsScreenState extends State<NetworkDetailsScreen> {
  final _appDatabase = AppDatabase.instance;
  List<MachineData> _machines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    final machines = await _appDatabase.machineDao.getMachinesForNetwork(
      widget.network.id,
    );
    setState(() {
      _machines = machines;
      _isLoading = false;
    });
  }

  Future<void> _refreshMachines() async {
    // In a real app, you would make an API call here to fetch the latest statuses.
    // TODO : Add an api route to get machine statuses
    // For now, we'll just reload from the database.
    await _loadMachines();
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
                        RouterStatusBadge(
                          isRunning: widget.network.isRouterRunning,
                        ),
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
                      'Machines (${_machines.length})',
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
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_machines.isEmpty)
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final machine = _machines[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _machines.length - 1 ? 24.0 : 0,
                    ),
                    child: MachineCard(
                      machine: machine,
                      network: widget.network,
                    ),
                  );
                }, childCount: _machines.length),
              ),
          ],
        ),
      ),
    );
  }
}
