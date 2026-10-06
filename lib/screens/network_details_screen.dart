import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
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

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    bool isDeleting = false;
    String enteredName = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final expectedSentence =
                'I want to delete the network ${widget.network.name}';
            final isNameMatching = enteredName.trim() == expectedSentence;

            return AlertDialog(
              title: Text(
                'Delete Network?',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to delete this network? All associated machines will also be permanently removed. This action cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  Text('Type "$expectedSentence" to confirm:'),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Network Name',
                    ),
                    onChanged: (value) {
                      setState(() {
                        enteredName = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: (!isNameMatching || isDeleting)
                      ? null
                      : () async {
                          setState(() {
                            isDeleting = true;
                          });
                          await _appDatabase.networkDao.deleteNetwork(
                            widget.network.id,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Network \'${widget.network.name}\' successfully deleted.',
                                ),
                              ),
                            );
                            Navigator.of(
                              context,
                            ).pop(true); // Return to home page with true
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.network.name),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            tooltip: 'Delete Network',
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.router,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'IP: ${widget.network.routerIp}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.memory,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MAC: ${widget.network.routerMacAddress}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
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
                    child: Dismissible(
                      key: ValueKey(machine.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete,
                          color: theme.colorScheme.onError,
                          size: 32,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete Machine?'),
                              content: Text(
                                "Are you sure you want to remove '${machine.name}' from this network?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        // 1. Delete from UI
                        setState(() {
                          _machines.removeAt(index);
                        });

                        // 2. Delete from Database
                        await _appDatabase.machineDao.deleteMachine(
                          machine.toCompanion(false),
                        );

                        // 3. Show feedback with Undo action
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Machine '${machine.name}' deleted.",
                              ),
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  // Restore in DB
                                  await _appDatabase.machineDao.insertMachine(
                                    machine
                                        .toCompanion(false)
                                        .copyWith(
                                          id: const drift.Value.absent(), // ensure it generates a new PK or use the same if safe
                                        ),
                                  );

                                  // We reload the network to place it back safely
                                  await _loadMachines();
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: MachineCard(
                        machine: machine,
                        network: widget.network,
                      ),
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
