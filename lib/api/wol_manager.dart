import 'dart:convert';

import 'package:sandman/constants/api_constants.dart';
import 'package:sandman/models/http_payloads/api_wol_response.dart';
import 'package:sandman/models/http_payloads/machine_status_response.dart';
import 'package:sandman/models/http_payloads/shutdown_payload.dart';
import 'package:sandman/models/http_payloads/wol_payload.dart';
import 'package:http/http.dart' as http;

class WolManager {
  final http.Client client;
  final Duration timeout;

  WolManager({http.Client? client, this.timeout = ApiConstants.requestTimeout})
    : client = client ?? http.Client();

  Uri _buildUri(
    String httpProtocol,
    String gatewayIp,
    int gatewayPort,
    String route,
  ) {
    return Uri.parse('$httpProtocol$gatewayIp:$gatewayPort$route');
  }

  Map<String, dynamic>? _tryDecodeJsonObject(String rawBody) {
    if (rawBody.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawBody);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  ApiWolResponse _parseWolResponse(http.Response response) {
    final body = _tryDecodeJsonObject(response.body);
    final message =
        (body?['message'] ?? body?['error']) as String? ?? 'Unknown Error';
    return ApiWolResponse(response.statusCode, message);
  }

  Future<ApiWolResponse> sendWolSignal(
    String httpProtocol,
    String gatewayIp,
    int gatewayPort,
    WolPayload wolPayload,
  ) async {
    final url = _buildUri(
      httpProtocol,
      gatewayIp,
      gatewayPort,
      ApiConstants.wakeonlanRoute,
    );

    final response = await client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(wolPayload.toJson()),
        )
        .timeout(timeout);

    return _parseWolResponse(response);
  }

  Future<ApiWolResponse> sendShutdownSignal(
    String httpProtocol,
    String gatewayIp,
    int gatewayPort,
    ShutdownPayload shutdownPayload,
  ) async {
    final url = _buildUri(
      httpProtocol,
      gatewayIp,
      gatewayPort,
      ApiConstants.shutdownRoute,
    );

    final response = await client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(shutdownPayload.toJson()),
        )
        .timeout(timeout);

    return _parseWolResponse(response);
  }

  /// Queries `GET /status/{machineIp}` on the gateway API to detect machine state.
  Future<MachineStatusResponse> getMachineStatus(
    String httpProtocol,
    String gatewayIp,
    int gatewayPort,
    String machineIp,
  ) async {
    final url = _buildUri(
      httpProtocol,
      gatewayIp,
      gatewayPort,
      '${ApiConstants.statusRoute}/${Uri.encodeComponent(machineIp)}',
    );

    final response = await client.get(url).timeout(timeout);
    final body = _tryDecodeJsonObject(response.body);

    if (body == null) {
      return MachineStatusResponse(
        statusCode: response.statusCode,
        message: response.body.isEmpty ? null : response.body,
      );
    }

    return MachineStatusResponse.fromJson(response.statusCode, body);
  }

  /// Checks whether the gateway Go API responds to HTTP requests.
  Future<bool> isGatewayReachable(
    String httpProtocol,
    String gatewayIp,
    int gatewayPort,
  ) async {
    final url = _buildUri(
      httpProtocol,
      gatewayIp,
      gatewayPort,
      ApiConstants.statusRoute,
    );

    try {
      final response = await client.get(url).timeout(timeout);
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
