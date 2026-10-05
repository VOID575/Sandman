import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sandman/models/api_wol_response.dart';
import 'package:sandman/models/wol_payload.dart';
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

      final mockPayload = WolPayload(fakeMacAddress,fakeBroadcastAddress, fakeIp);

      final mockClient = MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(
            request.url.toString(),
            '$fakeProtocol$fakeIp${ApiConstants.wakeonlanRoute}'
        );


        return http.Response('{"message": "Magic packet sent successfully"}', 200);
      });


      final wolManager = WolManager(client: mockClient);

      // Act
      final result = await wolManager.sendWolSignal(fakeProtocol, mockPayload);

      // Assert
      expect(result, isA<ApiWolResponse>());
      expect(result.statusCode, 200);
      expect(result.message, 'Magic packet sent successfully');
    });

    test('sendShutdownSignal should handle error response always', () async {
      // Arrange
      const String fakeMacAddress = '192.168.1.50';
      const String fakeIp = '192.168.1.50';
      const String fakeBroadcastAddress = '255.255.255.255';
      const String fakeProtocol = 'http://';

      final mockPayload = WolPayload(fakeMacAddress, fakeIp, fakeBroadcastAddress);

      final mockClient = MockClient((http.Request request) async {
        return http.Response('{"message": "Failed to reach machine"}', 500);
      });

      final wolManager = WolManager(client: mockClient);

      // Act
      final result = await wolManager.sendShutdownSignal(fakeProtocol, mockPayload);

      // Assert
      expect(result.statusCode, 500);
      expect(result.message, 'Failed to reach machine');
    });
  });
}