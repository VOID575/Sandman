import 'package:sandman/models/machine.dart';

/// Parsed HTTP response from the gateway API `GET /status/{ip}` endpoint.
class MachineStatusResponse {
  final int statusCode;
  final MachineStatus? status;
  final String? message;

  const MachineStatusResponse({
    required this.statusCode,
    this.status,
    this.message,
  });

  /// Whether the gateway responded with a 2xx status and a known machine state.
  bool get isSuccess => statusCode >= 200 && statusCode < 300 && status != null;

  factory MachineStatusResponse.fromJson(
    int statusCode,
    Map<String, dynamic> json,
  ) {
    final rawStatus = (json['status'] as String?)?.trim().toLowerCase();
    final parsedStatus = switch (rawStatus) {
      'online' => MachineStatus.online,
      'offline' => MachineStatus.offline,
      _ => null,
    };

    return MachineStatusResponse(
      statusCode: statusCode,
      status: parsedStatus,
      message: (json['message'] ?? json['error']) as String?,
    );
  }
}
