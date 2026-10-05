import 'dart:convert';

import 'package:sandman/models/api_wol_response.dart';
import 'package:sandman/models/wol_payload.dart';
import 'package:sandman/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class WolManager {
  Future<ApiWolResponse> sendWolSignal(
    String httpProtocol,
    WolPayload wolPayload,
  ) async {
    Uri url = Uri.parse(
      '$httpProtocol${wolPayload.virtualIpv4}${ApiConstants.wakeonlanRoute}',
    );

    http.Response response = await http.post(url);

    Map<String, String> body = jsonDecode(response.body) as Map<String, String>;
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

    http.Response response = await http.post(url);

    Map<String, String> body = jsonDecode(response.body) as Map<String, String>;
    return ApiWolResponse(response.statusCode, body['message']!);
  }
}
