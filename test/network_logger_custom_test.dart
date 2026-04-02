import 'package:flutter_test/flutter_test.dart';
import 'package:network_logger_custom/network_logger_custom.dart' as nlc;
import 'package:dio/dio.dart' as dio;

void main() {
  group('NetworkLogger Tests', () {
    test('Initial state is empty', () {
      final logger = nlc.NetworkLogger();
      expect(logger.events, isEmpty);
    });

    test('Add single event correctly', () {
      final logger = nlc.NetworkLogger();
      final event = nlc.NetworkEventLog(
        requestTimestamp: DateTime.now(),
        request: nlc.Request(
          uri: 'https://example.com',
          method: 'GET',
          headers: nlc.Headers([]),
        ),
      );

      logger.add(event);

      expect(logger.events.length, 1);
      expect(logger.events.first.request?.uri, 'https://example.com');
    });

    test('Clear events works', () {
      final logger = nlc.NetworkLogger();
      logger.add(nlc.NetworkEventLog());
      expect(logger.events.isNotEmpty, true);

      logger.clear();
      expect(logger.events.isEmpty, true);
    });
  });

  group('DioNetworkLogger Interceptor Tests', () {
    late dio.Dio d;

    setUp(() {
      d = dio.Dio();
      // Inject our custom logger instance for the test
      d.interceptors.add(nlc.DioNetworkLogger());
    });

    test('Interceptor should capture requests', () async {
      // Set up a mock or trigger a request that will fail (we just need the capture)
      try {
        await d.get('https://example.com',
            options: dio.Options(validateStatus: (_) => true));
      } catch (e) {
        // Silently fail, just checking the interceptor
      }

      // Check if the event was captured in the singleton/instance used by DioNetworkLogger
      expect(nlc.NetworkLogger.instance.events.isNotEmpty, true);
      expect(nlc.NetworkLogger.instance.events.first.request?.method, 'GET');
    });
  });
}
