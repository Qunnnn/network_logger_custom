import 'network_event.dart';
import 'network_logger.dart';
import 'package:dio/dio.dart' as dio;

/// A network logger implementation for Dio HTTP client
/// This class follows the Singleton pattern and implements Dio's Interceptor interface
class DioNetworkLogger extends dio.Interceptor {
  /// Singleton instance
  static final DioNetworkLogger _singleton =
      DioNetworkLogger._internal(NetworkLogger.instance);

  /// Factory constructor to get the singleton instance
  factory DioNetworkLogger() => _singleton;

  /// Internal constructor for singleton pattern
  DioNetworkLogger._internal(this.eventList);

  /// The event list to track network events
  final NetworkEventList eventList;

  /// Map to store ongoing requests
  final _requests = <dio.RequestOptions, NetworkEventLog>{};

  @override
  Future<void> onRequest(
    dio.RequestOptions options,
    dio.RequestInterceptorHandler handler,
  ) async {
    final event = NetworkEventLog.requestNow(
      request: options.toRequest(),
      error: null,
      response: null,
    );

    _requests[options] = event;
    eventList.add(event);

    handler.next(options);
  }

  @override
  void onResponse(
    dio.Response<dynamic> response,
    dio.ResponseInterceptorHandler handler,
  ) {
    final event = _requests[response.requestOptions];
    if (event != null) {
      _requests.remove(response.requestOptions);
      eventList.updated(
        event
          ..response = response.toResponse()
          ..responseTimestamp = DateTime.now()
          ..requestTimestamp = event.requestTimestamp,
      );
    } else {
      eventList.add(
        NetworkEventLog.responseNow(
          requestTimestamp: event?.requestTimestamp,
          request: response.requestOptions.toRequest(),
          response: response.toResponse(),
        ),
      );
    }
  }

  @override
  void onError(dio.DioException err, dio.ErrorInterceptorHandler handler) {
    final event = _requests[err.requestOptions];
    if (event != null) {
      _requests.remove(err.requestOptions);
      eventList.updated(
        event
          ..error = err.toNetworkError()
          ..response = err.response?.toResponse()
          ..requestTimestamp = event.requestTimestamp
          ..responseTimestamp = DateTime.now(),
      );
    } else {
      eventList.add(
        NetworkEventLog.responseNow(
          request: err.requestOptions.toRequest(),
          response: err.response?.toResponse(),
          error: err.toNetworkError(),
        ),
      );
    }
  }
}

/// Extension methods for Dio RequestOptions
extension _RequestOptionsX on dio.RequestOptions {
  /// Converts Dio RequestOptions to a NetworkLogger Request
  Request toRequest() => Request(
        uri: uri.toString(),
        data: data,
        method: method,
        headers: Headers(
          headers.entries.map(
            (kv) => MapEntry(kv.key, '${kv.value}'),
          ),
        ),
      );
}

/// Extension methods for Dio Response
extension _ResponseX on dio.Response<dynamic> {
  /// Converts Dio Response to a NetworkLogger Response
  Response toResponse() => Response(
        data: data,
        statusCode: statusCode ?? -1,
        statusMessage: statusMessage ?? 'unknown',
        headers: Headers(
          headers.map.entries.fold<List<MapEntry<String, String>>>(
            [],
            (p, e) => p..addAll(e.value.map((v) => MapEntry(e.key, v))),
          ),
        ),
      );
}

/// Extension methods for DioException
extension _DioErrorX on dio.DioException {
  /// Converts DioException to a NetworkLogger NetworkError
  NetworkError toNetworkError() => NetworkError(message: toString());
}
