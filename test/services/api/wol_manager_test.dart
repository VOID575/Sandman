import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sandman/models/machine.dart';
import 'package:sandman/models/http_payloads/api_wol_response.dart';
import 'package:sandman/models/http_payloads/machine_status_response.dart';
import 'package:sandman/models/http_payloads/wol_payload.dart';
import 'package:sandman/models/http_payloads/shutdown_payload.dart';
import 'package:sandman/constants/api_constants.dart';
import 'package:sandman/api/wol_manager.dart';

void main() {
  group('WolManager', () {
    test('sendWolSignal should parse the response correctly always', () async {
      // Arrange
      const String fakeMacAddress = '192.168.1.50';
      const String fakeIp = '192.168.1.50';
      const String fakeProtocol = 'http://';
      const String fakeBroadcastAddress = '255.255.255.255';
      const String fakeGatewayIp = '100.100.100.1';
      const int fakeGatewayPort = 8080;

      final mockPayload = WolPayload(
        fakeMacAddress,
        fakeBroadcastAddress,
        fakeIp,
      );

      final mockClient = MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          '$fakeProtocol$fakeGatewayIp:$fakeGatewayPort${ApiConstants.wakeonlanRoute}',
        );

        return http.Response(
          '{"message": "Magic packet sent successfully"}',
          200,
        );
      });

      final wolManager = WolManager(client: mockClient);

      // Act
      final result = await wolManager.sendWolSignal(
        fakeProtocol,
        fakeGatewayIp,
        fakeGatewayPort,
        mockPayload,
      );

      // Assert
      expect(result, isA<ApiWolResponse>());
      expect(result.statusCode, 200);
      expect(result.message, 'Magic packet sent successfully');
    });

    test('sendShutdownSignal should handle error response always', () async {
      // Arrange
      const String fakeIp = '192.168.1.50';
      const String fakeProtocol = 'http://';
      const String fakeGatewayIp = '100.100.100.1';
      const int fakeGatewayPort = 8080;

      final mockPayload = ShutdownPayload(fakeIp, 'linux', 'ubuntu');

      final mockClient = MockClient((http.Request request) async {
        return http.Response('{"message": "Failed to reach machine"}', 500);
      });

      final wolManager = WolManager(client: mockClient);

      // Act
      final result = await wolManager.sendShutdownSignal(
        fakeProtocol,
        fakeGatewayIp,
        fakeGatewayPort,
        mockPayload,
      );

      // Assert
      expect(result.statusCode, 500);
      expect(result.message, 'Failed to reach machine');
    });

    test('getMachineStatus parses online and offline JSON responses', () async {
      const String fakeProtocol = 'http://';
      const String fakeGatewayIp = '100.100.100.1';
      const int fakeGatewayPort = 8080;
      const String machineIp = '100.64.0.12';

      final mockClient = MockClient((http.Request request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          '$fakeProtocol$fakeGatewayIp:$fakeGatewayPort${ApiConstants.statusRoute}/$machineIp',
        );
        return http.Response('{"status": "online"}', 200);
      });

      final wolManager = WolManager(client: mockClient);

      final result = await wolManager.getMachineStatus(
        fakeProtocol,
        fakeGatewayIp,
        fakeGatewayPort,
        machineIp,
      );

      expect(result, isA<MachineStatusResponse>());
      expect(result.statusCode, 200);
      expect(result.isSuccess, isTrue);
      expect(result.status, MachineStatus.online);
    });

    test(
      'getMachineStatus handles offline, unknown, and error payloads safely',
      () async {
        const String fakeProtocol = 'http://';
        const String fakeGatewayIp = '100.100.100.1';
        const int fakeGatewayPort = 8080;

        final offlineClient = MockClient(
          (_) async => http.Response('{"status": "OFFLINE"}', 200),
        );
        final offlineResult = await WolManager(client: offlineClient)
            .getMachineStatus(
              fakeProtocol,
              fakeGatewayIp,
              fakeGatewayPort,
              '100.64.0.15',
            );
        expect(offlineResult.isSuccess, isTrue);
        expect(offlineResult.status, MachineStatus.offline);

        final errorClient = MockClient(
          (_) async => http.Response('{"error": "ping failed"}', 500),
        );
        final errorResult = await WolManager(client: errorClient)
            .getMachineStatus(
              fakeProtocol,
              fakeGatewayIp,
              fakeGatewayPort,
              '100.64.0.15',
            );
        expect(errorResult.isSuccess, isFalse);
        expect(errorResult.status, isNull);
        expect(errorResult.message, 'ping failed');

        final nonJsonClient = MockClient(
          (_) async => http.Response('Bad Gateway', 502),
        );
        final nonJsonResult = await WolManager(client: nonJsonClient)
            .getMachineStatus(
              fakeProtocol,
              fakeGatewayIp,
              fakeGatewayPort,
              '100.64.0.15',
            );
        expect(nonJsonResult.isSuccess, isFalse);
        expect(nonJsonResult.statusCode, 502);
        expect(nonJsonResult.message, 'Bad Gateway');
      },
    );

    test(
      'isGatewayReachable returns true on < 500 and false on >= 500 or errors',
      () async {
        const String fakeProtocol = 'http://';
        const String fakeGatewayIp = '100.100.100.1';
        const int fakeGatewayPort = 8080;

        final okManager = WolManager(
          client: MockClient((request) async {
            expect(
              request.url.toString(),
              '$fakeProtocol$fakeGatewayIp:$fakeGatewayPort${ApiConstants.statusRoute}',
            );
            return http.Response('', 404);
          }),
        );
        expect(
          await okManager.isGatewayReachable(
            fakeProtocol,
            fakeGatewayIp,
            fakeGatewayPort,
          ),
          isTrue,
        );

        final proxyDownManager = WolManager(
          client: MockClient((_) async => http.Response('Bad Gateway', 502)),
        );
        expect(
          await proxyDownManager.isGatewayReachable(
            fakeProtocol,
            fakeGatewayIp,
            fakeGatewayPort,
          ),
          isFalse,
        );

        final timeoutManager = WolManager(
          timeout: const Duration(milliseconds: 10),
          client: MockClient((_) => Completer<http.Response>().future),
        );
        expect(
          await timeoutManager.isGatewayReachable(
            fakeProtocol,
            fakeGatewayIp,
            fakeGatewayPort,
          ),
          isFalse,
        );
      },
    );
  });
}
