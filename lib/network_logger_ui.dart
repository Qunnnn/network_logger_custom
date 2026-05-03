import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'enumerate_items.dart';
import 'network_event.dart';
import 'network_logger.dart';
import 'package:dio/dio.dart' as dio;

/// Overlay for [NetworkLoggerButton].
class NetworkLoggerOverlay extends StatefulWidget {
  static const double _defaultPadding = 30;
  const NetworkLoggerOverlay._({
    required this.right,
    required this.bottom,
    required this.draggable,
  });
  final double bottom;
  final double right;
  final bool draggable;

  /// Attach overlay to specified [context].
  static OverlayEntry attachTo(
    BuildContext context, {
    bool rootOverlay = true,
    double bottom = _defaultPadding,
    double right = _defaultPadding,
    bool draggable = true,
  }) {
    // create overlay entry
    final entry = OverlayEntry(
      builder: (context) => NetworkLoggerOverlay._(
        bottom: bottom,
        right: right,
        draggable: draggable,
      ),
    );
    // insert on next frame
    Future.delayed(Duration.zero, () {
      if (!context.mounted) return;
      Overlay.of(context, rootOverlay: rootOverlay).insert(entry);
    });
    // return
    return entry;
  }

  @override
  State<NetworkLoggerOverlay> createState() => _NetworkLoggerOverlayState();
}

class _NetworkLoggerOverlayState extends State<NetworkLoggerOverlay> {
  static const Size buttonSize = Size(57, 57);
  late double bottom = widget.bottom;
  late double right = widget.right;
  late MediaQueryData screen;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screen = MediaQuery.of(context);
  }

  Offset? lastPosition;
  void onPanUpdate(LongPressMoveUpdateDetails details) {
    final delta = lastPosition! - details.localPosition;
    bottom += delta.dy;
    right += delta.dx;
    lastPosition = details.localPosition;

    /// Checks if the button went of screen
    if (bottom < 0) {
      bottom = 0;
    }
    if (right < 0) {
      right = 0;
    }
    if (bottom + buttonSize.height > screen.size.height) {
      bottom = screen.size.height - buttonSize.height;
    }
    if (right + buttonSize.width > screen.size.width) {
      right = screen.size.width - buttonSize.width;
    }
    setState(() {});
  }

  void onPanEnd() {
    setState(() => lastPosition = null);
    final centerX = screen.size.width / 2;
    final buttonCenterX = screen.size.width - right - (buttonSize.width / 2);
    
    if (buttonCenterX > centerX) {
      right = 0;
    } else {
      right = screen.size.width - buttonSize.width;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.draggable) {
      return AnimatedPositioned(
        duration: lastPosition == null 
            ? const Duration(milliseconds: 300) 
            : Duration.zero,
        curve: Curves.easeOutCubic,
        right: right,
        bottom: bottom,
        child: GestureDetector(
          onLongPressMoveUpdate: onPanUpdate,
          onLongPressUp: onPanEnd,
          onLongPressDown: (details) {
            setState(() => lastPosition = details.localPosition);
          },
          child: Material(
            elevation: lastPosition == null ? 0 : 30,
            borderRadius: BorderRadius.all(Radius.circular(buttonSize.width)),
            child: NetworkLoggerButton(),
          ),
        ),
      );
    }
    return Positioned(
      right: widget.right + screen.padding.right,
      bottom: widget.bottom + screen.padding.bottom,
      child: NetworkLoggerButton(),
    );
  }
}

/// [FloatingActionButton] that opens [NetworkLoggerScreen] when pressed.
class NetworkLoggerButton extends StatefulWidget {
  /// Source event list (default: [NetworkLogger.instance])
  final NetworkEventList eventList;

  /// Blink animation period
  final Duration blinkPeriod;
  // Button background color
  final Color color;

  /// If set to true this button will be hidden on non-debug builds.
  final bool showOnlyOnDebug;
  NetworkLoggerButton({
    super.key,
    this.color = Colors.deepPurple,
    this.blinkPeriod = const Duration(seconds: 1, microseconds: 500),
    this.showOnlyOnDebug = false,
    NetworkEventList? eventList,
  }) : eventList = eventList ?? NetworkLogger.instance;
  @override
  State<NetworkLoggerButton> createState() => _NetworkLoggerButtonState();
}

class _NetworkLoggerButtonState extends State<NetworkLoggerButton> {
  StreamSubscription<UpdateEvent>? _subscription;
  Timer? _blinkTimer;
  bool _visible = true;
  int _blink = 0;
  Future<void> _press() async {
    setState(() {
      _visible = false;
    });
    try {
      await NetworkLoggerScreen.open(context, eventList: widget.eventList);
    } finally {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant NetworkLoggerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventList != widget.eventList) {
      _subscription?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.eventList.stream.listen((event) {
      if (mounted) {
        setState(() {
          _blink = _blink % 2 == 0 ? 6 : 5;
        });
      }
    });
  }

  @override
  void initState() {
    _subscribe();
    _blinkTimer = Timer.periodic(widget.blinkPeriod, (timer) {
      if (_blink > 0 && mounted) {
        setState(() {
          _blink--;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox();
    }
    return _DebugOnly(
      enabled: widget.showOnlyOnDebug,
      child: FloatingActionButton(
        onPressed: _press,
        backgroundColor: widget.color,
        child: Icon(
          (_blink % 2 == 0) ? Icons.cloud : Icons.cloud_queue,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Screen that displays log entries list.
class NetworkLoggerScreen extends StatefulWidget {
  NetworkLoggerScreen({
    super.key,
    NetworkEventList? eventList,
    this.baseUrls = const [],
    this.isHiddenBaseUrl = false,
  }) : eventList = eventList ?? NetworkLogger.instance;

  /// Event list to listen for event changes.
  final NetworkEventList eventList;
  //Specific base url to hide it
  final List<String> baseUrls;
  final bool isHiddenBaseUrl;

  /// Opens screen.
  static Future<void> open(
    BuildContext context, {
    NetworkEventList? eventList,
    List<String> baseUrls = const [],
    bool isHiddenBaseUrl = false,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetworkLoggerScreen(
          eventList: eventList,
          baseUrls: baseUrls,
          isHiddenBaseUrl: isHiddenBaseUrl,
        ),
      ),
    );
  }

  @override
  State<NetworkLoggerScreen> createState() => _NetworkLoggerScreenState();
}

class _NetworkLoggerScreenState extends State<NetworkLoggerScreen> {
  final TextEditingController searchController = TextEditingController();
  bool filterSuccess = false;
  bool filterError = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// filter events with search keyword and chips
  List<NetworkEventLog> getEvents() {
    Iterable<NetworkEventLog> events = widget.eventList.events;

    if (filterSuccess) {
      events = events.where((e) => e.response != null && e.response!.statusCode >= 200 && e.response!.statusCode < 300);
    } else if (filterError) {
      events = events.where((e) => e.error != null || (e.response != null && e.response!.statusCode >= 400));
    }

    if (searchController.text.isEmpty) return events.toList();
    final query = searchController.text.toLowerCase();
    
    return events.where((it) {
      if (it.request?.uri.toLowerCase().contains(query) ?? false) return true;
      if (it.request?.method.toLowerCase().contains(query) ?? false) return true;
      if (it.response?.statusCode.toString().contains(query) ?? false) return true;
      if (it.request?.data?.toString().toLowerCase().contains(query) ?? false) return true;
      if (it.response?.data?.toString().toLowerCase().contains(query) ?? false) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Network Logs'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.copy,
              color: Colors.blue,
            ),
            onPressed: () {
              final jsonStr = jsonEncode(widget.eventList.events.map((e) => {
                'request': {
                  'uri': e.request?.uri,
                  'method': e.request?.method,
                  'headers': e.request?.headers.entries.map((h) => {h.key: h.value}).toList(),
                  'data': e.request?.data.toString(),
                  'timestamp': e.requestTimestamp?.toIso8601String(),
                },
                'response': e.response != null ? {
                  'statusCode': e.response?.statusCode,
                  'statusMessage': e.response?.statusMessage,
                  'headers': e.response?.headers.entries.map((h) => {h.key: h.value}).toList(),
                  'data': e.response?.data.toString(),
                  'timestamp': e.responseTimestamp?.toIso8601String(),
                } : null,
                'error': e.error?.toString(),
              }).toList());
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session copied to clipboard')),
              );
            },
            tooltip: 'Export Session',
          ),
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: widget.eventList.clear,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: widget.eventList.stream,
        builder: (context, snapshot) {
          // filter events with search keyword
          final events = getEvents();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextField(
                  controller: searchController,
                  onChanged: (text) {
                    setState(() {});
                  },
                  autocorrect: false,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    prefixIcon: const Icon(Icons.search, color: Colors.black26),
                    suffix: searchController.text.isNotEmpty
                          ? Text('${events.length} results')
                          : const SizedBox(),
                    hintText: 'Search URL, body, status...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Success (2xx)'),
                      selected: filterSuccess,
                      onSelected: (val) {
                        setState(() {
                          filterSuccess = val;
                          if (val) filterError = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Errors (4xx, 5xx)'),
                      selected: filterError,
                      onSelected: (val) {
                        setState(() {
                          filterError = val;
                          if (val) filterSuccess = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: enumerateItems<NetworkEventLog>(
                    events,
                    buildItem,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildItem(BuildContext context, NetworkEventLog item) {
    var urlText = item.request?.uri ?? 'Unknown URL';
    if (widget.isHiddenBaseUrl) {
      for (var element in widget.baseUrls) {
        if (urlText.contains(element)) {
          urlText = urlText.replaceAll(element, '/');
        }
      }
    }
    return ListTile(
      key: ValueKey(item.request),
      tileColor: item.error == null
          ? (item.response == null ? Colors.amber.withAlpha(76) : Colors.green.withAlpha(51))
          : Colors.red.withAlpha(51),
      title: Text(
        item.request?.method ?? 'UNKNOWN',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        urlText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Text(
        (item.response?.statusCode)?.toString() ?? '-',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      trailing: item.response != null
          ? _RequestTrailing(
              event: item,
            )
          : null,
      onTap: () => NetworkLoggerEventScreen.open(
        context,
        item,
        widget.eventList,
      ),
    );
  }
}

const _jsonEncoder = JsonEncoder.withIndent('  ');

/// Screen that displays log entry details.
class NetworkLoggerEventScreen extends StatelessWidget {
  const NetworkLoggerEventScreen({super.key, required this.event});
  static Route<void> route({
    required NetworkEventLog event,
    required NetworkEventList eventList,
  }) {
    return MaterialPageRoute(
      builder: (context) => StreamBuilder(
        stream: eventList.stream.where((item) => item.event == event),
        builder: (context, snapshot) => NetworkLoggerEventScreen(event: event),
      ),
    );
  }

  /// Opens screen.
  static Future<void> open(
    BuildContext context,
    NetworkEventLog event,
    NetworkEventList eventList,
  ) {
    return Navigator.of(context).push(
      route(
        event: event,
        eventList: eventList,
      ),
    );
  }

  /// Which event to display details for.
  final NetworkEventLog event;
  Widget buildBodyViewer(BuildContext context, dynamic body) {
    dynamic decodedBody = body;
    if (body is String) {
      try {
        decodedBody = json.decode(body);
      } catch (_) {}
    }
    
    if (decodedBody is Map || decodedBody is List) {
      return Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: JsonViewer(decodedBody),
        ),
      );
    }
    
    String text = body?.toString() ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: ['sans-serif'],
        ),
      ),
    );
  }

  Widget buildHeadersViewer(
    BuildContext context,
    List<MapEntry<String, String>> headers,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: headers.map((e) => SelectableText(e.key)).toList(),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: headers.map((e) => SelectableText(e.value)).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildRequestView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 15),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
          child: Text('URL', style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.request!.method,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 15),
              Expanded(child: SelectableText(event.request!.uri.toString())),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
          child:
              Text('TIMESTAMP', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(event.requestTimestamp.toString()),
        ),
        if (event.request!.headers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child:
                Text('HEADERS', style: Theme.of(context).textTheme.bodyMedium),
          ),
          buildHeadersViewer(context, event.request!.headers.entries),
        ],
        if (event.error != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child: Text('ERROR', style: Theme.of(context).textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              event.error.toString(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
          child: Text('BODY', style: Theme.of(context).textTheme.bodyMedium),
        ),
        buildBodyViewer(context, event.request!.data),
      ],
    );
  }

  Widget buildResponseView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 15),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
          child: Text('RESULT', style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.response!.statusCode.toString(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(event.response!.statusMessage)),
            ],
          ),
        ),
        if (event.response?.headers.isNotEmpty ?? false) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child:
                Text('HEADERS', style: Theme.of(context).textTheme.bodyMedium),
          ),
          buildHeadersViewer(
            context,
            event.response?.headers.entries ?? [],
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
          child: Text('BODY', style: Theme.of(context).textTheme.bodyMedium),
        ),
        buildBodyViewer(context, event.response?.data),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showResponse = event.response != null;
    Widget? bottom;
    if (showResponse) {
      bottom = const TabBar(
        tabs: [
          Tab(text: 'Request'),
          Tab(text: 'Response'),
        ],
      );
    }
    return DefaultTabController(
      length: showResponse ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log Entry'),
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          actions: <Widget>[
            if (showResponse)
              IconButton(
                icon: const Icon(Icons.data_object, color: Colors.black),
                tooltip: 'Copy Response JSON',
                onPressed: () {
                  final text = event.response?.data is String
                      ? event.response?.data as String
                      : _jsonEncoder.convert(event.response?.data);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Response Body copied')),
                  );
                },
              ),
            IconButton(
              icon: const Icon(
                Icons.copy,
                color: Colors.black,
              ),
              tooltip: 'Copy cURL',
              onPressed: () {
                if (event.request != null) {
                  final curl =
                      RequestToCurlConverter.requestToCurl(event.request!);
                  Clipboard.setData(ClipboardData(text: curl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('cURL copied to clipboard')),
                  );
                }
              },
            ),
          ],
          bottom: bottom as PreferredSizeWidget?,
        ),
        body: Builder(
          builder: (context) => TabBarView(
            children: <Widget>[
              buildRequestView(context),
              if (showResponse) buildResponseView(context),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestTrailing extends StatelessWidget {
  const _RequestTrailing({
    required this.event,
  });
  final NetworkEventLog event;
  @override
  Widget build(BuildContext context) {
    final date = event.responseTimestamp;
    final triggerTime = event.requestTimestamp;
    final diff =
        (date!.millisecondsSinceEpoch - triggerTime!.millisecondsSinceEpoch)
            .abs();
    return Text(
      '$diff ms',
    );
  }
}

class _DebugOnly extends StatelessWidget {
  const _DebugOnly({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (enabled) {
      if (!kDebugMode) {
        return const SizedBox();
      }
    }
    return child;
  }
}

class RequestToCurlConverter {
  static String requestToCurl(Request request) {
    // Start building the cURL command
    final List<String> curlCommand = ['curl'];
    curlCommand.add('-X ${request.method}');
    // Add the headers
    if (request.headers.isNotEmpty) {
      final headersString = request.headers.map((key, value) {
        return '-H "$key: $value"';
      }).join(' ');
      curlCommand.add(headersString);
    }
    // Add the request data if it exists
    if (request.data != null) {
      if (request.data is dio.FormData) {
        final formData = request.data as dio.FormData;
        for (var field in formData.fields) {
          curlCommand.add('-F "${field.key}=${field.value}"');
        }
        for (var file in formData.files) {
          curlCommand.add('-F "${file.key}=@${file.value.filename ?? "file"}"');
        }
      } else {
        try {
          final jsonData = json.encode(request.data);
          curlCommand.add('-d \'$jsonData\'');
        } catch (e) {
          curlCommand.add('-d \'${request.data.toString()}\'');
        }
      }
    }
    // Add the URI
    curlCommand.add('\'${request.uri}\'');
    // Join all parts into a single string
    final curlString = curlCommand.join(' ');
    return curlString;
  }
}

class JsonViewer extends StatefulWidget {
  final dynamic jsonObj;
  const JsonViewer(this.jsonObj, {super.key});

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.jsonObj is Map) {
      final map = widget.jsonObj as Map;
      if (map.isEmpty) return const Text('{}');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isExpanded ? Icons.arrow_drop_down : Icons.arrow_right, size: 16),
                const Text('Object {', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: map.entries.map((e) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Expanded(child: JsonViewer(e.value)),
                  ],
                )).toList(),
              ),
            ),
          if (_isExpanded) const Text('}'),
        ],
      );
    } else if (widget.jsonObj is List) {
      final list = widget.jsonObj as List;
      if (list.isEmpty) return const Text('[]');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isExpanded ? Icons.arrow_drop_down : Icons.arrow_right, size: 16),
                Text('Array [${list.length}]', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list.asMap().entries.map((e) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('[${e.key}]: ', style: const TextStyle(color: Colors.grey)),
                    Expanded(child: JsonViewer(e.value)),
                  ],
                )).toList(),
              ),
            ),
          if (_isExpanded) const Text(']'),
        ],
      );
    } else {
      return SelectableText(
        widget.jsonObj?.toString() ?? 'null',
        style: const TextStyle(color: Colors.green, fontFamily: 'monospace'),
      );
    }
  }
}
