import 'dart:async';
import 'network_event.dart';

/// List that contains network events and notifies dependents on updates.
class NetworkEventList {
  NetworkEventList({this.maxEntries = 500});

  /// Maximum number of events to keep in memory to prevent OOM errors.
  int maxEntries;

  final _controller = StreamController<UpdateEvent>.broadcast();

  /// Logged network events
  final events = <NetworkEventLog>[];

  /// A source of asynchronous network events.
  Stream<UpdateEvent> get stream => _controller.stream;

  /// Notify dependents that [event] is updated.
  void updated(NetworkEventLog event) {
    _controller.add(UpdateEvent(event));
  }

  /// Add [event] to [events] list and notify dependents.
  void add(NetworkEventLog event) {
    events.insert(0, event);
    while (events.length > maxEntries) {
      events.removeLast();
    }
    _controller.add(UpdateEvent(event));
  }

  /// Clear [events] and notify dependents.
  void clear() {
    events.clear();
    _controller.add(const UpdateEvent.clear());
  }

  /// Dispose resources.
  void dispose() {
    _controller.close();
  }
}

/// Event notified by [NetworkEventList.stream].
class UpdateEvent {
  const UpdateEvent(this.event);
  const UpdateEvent.clear() : event = null;
  final NetworkEventLog? event;
}

/// Network logger interface.
class NetworkLogger extends NetworkEventList {
  NetworkLogger({super.maxEntries});
  static final NetworkLogger instance = NetworkLogger();
}
