class WolPayload {
  final String macAddress;
  final String broadcastAddress;
  final String virtualIpv4;

  WolPayload(this.macAddress, this.broadcastAddress, this.virtualIpv4);

  Map<String, dynamic> toJson() => {
    'mac_address': macAddress,
    'broadcast_address': broadcastAddress,
    'ip': virtualIpv4,
  };
}
