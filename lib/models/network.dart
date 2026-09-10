class Network {
  final String name;
  final String description;
  final int totalMachines;
  final int runningMachines;
  final bool isRouterRunning;

  Network({
    required this.name,
    required this.description,
    required this.totalMachines,
    required this.runningMachines,
    required this.isRouterRunning,
  });
}
