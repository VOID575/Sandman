import 'dart:convert';

import 'package:sandman/models/http_payloads/api_wol_response.dart';
import 'package:sandman/models/http_payloads/wol_payload.dart';
import 'package:sandman/models/http_payloads/shutdown_payload.dart';
import 'package:sandman/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class WolManager {
  final http.Client client;

  WolManager({http.Client? client}) : client = client ?? http.Client();

  Future<ApiWolResponse> sendWolSignal(
    String httpProtocol,
    String routerIp,
    int routerPort,
    WolPayload wolPayload,
  ) async {
    Uri url = Uri.parse(
      '$httpProtocol$routerIp:$routerPort${ApiConstants.wakeonlanRoute}',
    );

    http.Response response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(wolPayload.toJson()),
    );

    Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    ApiWolResponse apiWolResponse = ApiWolResponse(
      response.statusCode,
      body['message']!,
    );

    return apiWolResponse;
  }

  Future<ApiWolResponse> sendShutdownSignal(
    String httpProtocol,
    String routerIp,
    int routerPort,
    ShutdownPayload shutdownPayload,
  ) async {
    Uri url = Uri.parse(
      '$httpProtocol$routerIp:$routerPort${ApiConstants.shutdownRoute}',
    );

    http.Response response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(shutdownPayload.toJson()),
    );

    Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    return ApiWolResponse(
      response.statusCode,
      body['message'] ?? body['error'] ?? 'Unknown Error',
    );
  }
}
