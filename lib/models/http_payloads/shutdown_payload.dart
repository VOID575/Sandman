class ShutdownPayload {
  final String ip;
  final String os;
  final String user;

  ShutdownPayload(this.ip, this.os, this.user);

  Map<String, dynamic> toJson() => {'ip': ip, 'os': os, 'user': user};
}
