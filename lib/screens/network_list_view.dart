import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../widgets/network_card.dart';
import 'network_details_screen.dart';

class NetworkListView extends StatelessWidget {
  final List<NetworkData> networks;
  final VoidCallback onCreateNetwork;

  const NetworkListView({
    super.key,
    required this.networks,
    required this.onCreateNetwork,
  });

  @override
  Widget build(BuildContext context) {
    if (networks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hub_outlined,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No networks yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first network to start managing your virtual machines and routers.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onCreateNetwork,
                icon: const Icon(Icons.add),
                label: const Text('Create Network'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: networks.length,
      itemBuilder: (context, index) {
        final network = networks[index];
        return NetworkCard(
          network: network,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NetworkDetailsScreen(network: network),
              ),
            );
          },
        );
      },
    );
  }
}
