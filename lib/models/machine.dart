enum MachineStatus {
  online,
  offline,
  wakingUp,
}

class Machine {
  final String name;
  final String tailscaleIp;
  final String macAddress;
  MachineStatus status;

  Machine({
    required this.name,
    required this.tailscaleIp,
    required this.macAddress,
    this.status = MachineStatus.offline,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'tailscale_ip': tailscaleIp,
      'name': name,
      'mac_address': macAddress,
    };
    // Add id only if it exists
    // if (id != null) {
    //   map['id'] = id;
    // }
    return map;
  }

  // Deserialisation (DB -> Objet) : runtime instanciation
  factory Machine.fromMap(Map<String, dynamic> map) {
    return Machine(
      // id: map['id'],
      name: map['name'],
      tailscaleIp: map['tailscale_ip'],
      macAddress: map['mac_address'],
      status: map['status'],
    );
  }
}
