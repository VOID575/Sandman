import 'package:flutter/material.dart';
import '../models/network.dart';
import '../models/machine.dart';
import 'network_list_view.dart';
import 'create_network_screen.dart';
import 'package:sandman/helpers/database/database_helper.dart';

class HomePage extends StatefulWidget {
  final String title;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isMenuOpen = false;
  
  final List<Network> _networks = [
    Network(
      name: 'Production Environment',
      description: 'Main production network handling all user traffic and backend services.',
      machines: [
        Machine(
            name: 'Web Server', 
            tailscaleIp: '100.100.100.1', 
            macAddress: 'AA:BB:CC:DD:EE:01',
            status: MachineStatus.online,
        ),
        Machine(
            name: 'Database', 
            tailscaleIp: '100.100.100.2', 
            macAddress: 'AA:BB:CC:DD:EE:02',
            status: MachineStatus.online,
        ),
      ],
      routerIp: '192.168.1.1',
      routerPort: 9,
      runningMachines: 2,
      isRouterRunning: true,
    ),
    Network(
      name: 'Testing Sandbox',
      description: 'Isolated network for testing new features and staging deployments.',
      machines: [
        Machine(
            name: 'Test Server', 
            tailscaleIp: '100.100.100.3', 
            macAddress: 'AA:BB:CC:DD:EE:03',
            status: MachineStatus.offline,
        ),
      ],
      routerIp: '192.168.2.1',
      routerPort: 9,
      runningMachines: 0,
      isRouterRunning: false,
    ),
  ];

  void _toggleSettingsMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }
  
  Future<void> _createNewNetwork() async {
    final newNetwork = await Navigator.of(context).push<Network>(
      MaterialPageRoute(
        builder: (context) => const CreateNetworkScreen(),
      ),
    );

    if (newNetwork != null) {
      setState(() {
        _networks.add(newNetwork);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network added successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double settingsMenuWidth = 250;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          widget.title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _toggleSettingsMenu,
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: Stack(
        children: [
          NetworkListView(
            networks: _networks,
            onCreateNetwork: _createNewNetwork,
          ),
          
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleSettingsMenu,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
            
          // Settings Menu Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isMenuOpen ? 0 : -settingsMenuWidth,
            top: 0,
            bottom: 0,
            width: settingsMenuWidth,
            child: Material(
              elevation: 8,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _toggleSettingsMenu,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dark mode',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Switch(
                            value: widget.isDarkMode,
                            onChanged: widget.onThemeChanged,
                            activeThumbColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNetwork,
        tooltip: 'Create Network',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
