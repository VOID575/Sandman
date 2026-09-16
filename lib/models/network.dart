import 'machine.dart';

class Network {
  final String name;
  final String description;
  final List<Machine> machines;
  final String routerIp;
  final int routerPort;
  final int runningMachines;
  final bool isRouterRunning;

  Network({
    required this.name,
    required this.description,
    required this.machines,
    required this.routerIp,
    required this.routerPort,
    required this.runningMachines,
    required this.isRouterRunning,
  });

  int get totalMachines => machines.length;
}
