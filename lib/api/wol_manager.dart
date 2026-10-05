import 'dart:convert';

import 'package:sandman/models/api_wol_response.dart';
import 'package:sandman/models/wol_payload.dart';
import 'package:sandman/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class WolManager {
  final http.Client client;

  WolManager({http.Client? client}) : client = client ?? http.Client();

  Future<ApiWolResponse> sendWolSignal(
    String httpProtocol,
    WolPayload wolPayload,
  ) async {
    Uri url = Uri.parse(
      '$httpProtocol${wolPayload.virtualIpv4}${ApiConstants.wakeonlanRoute}',
    );

    http.Response response = await client.post(url);

    Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    ApiWolResponse apiWolResponse = ApiWolResponse(
      response.statusCode,
      body['message']!,
    );

    return apiWolResponse;
  }

  Future<ApiWolResponse> sendShutdownSignal(
    String httpProtocol,
    WolPayload wolPayload,
  ) async {
    Uri url = Uri.parse(
      '$httpProtocol${wolPayload.virtualIpv4}${ApiConstants.shutdownRoute}',
    );

    http.Response response = await client.post(url);

    Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    return ApiWolResponse(response.statusCode, body['message']!);
  }
}
