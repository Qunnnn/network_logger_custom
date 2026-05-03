# Custom Network Logger

A lightweight, powerful network logging UI for Flutter applications using the **Dio** HTTP client. It captures all your network traffic and provides a beautiful, searchable overlay for inspection and debugging.

## Features
- 🚀 **One-Tap Integration**: Easily add as a Dio interceptor.
- 🔍 **Real-time Inspection**: Drill down into requests, responses, headers, and errors with a collapsible **JSON Tree Viewer**.
- 🔎 **Deep Search**: Search through URLs, HTTP methods, status codes, and JSON bodies.
- 🚥 **Quick Filters**: Instantly filter logs by Success (2xx) or Errors (4xx/5xx).
- 🛠️ **cURL & JSON Export**: Copy request details as cURL (including `FormData` support) or export the full session as JSON.
- 📱 **Smart Draggable Overlay**: Access logs from a floating button that snaps smoothly to screen edges.
- 🧠 **Memory Managed**: Automatically evicts old logs to keep your app's memory footprint low.

## Getting Started

### 1. Installation
Add `network_logger_custom` to your `pubspec.yaml`:
```yaml
dependencies:
  network_logger_custom: ^1.1.0
```

### 2. Basic Setup
Add the `DioNetworkLogger` interceptor to your Dio instance. You can optionally configure the `maxEntries` limit (default is 500):

```dart
import 'package:dio/dio.dart';
import 'package:network_logger_custom/network_logger_custom.dart';

final dio = Dio();

// Optional: Configure memory limits
NetworkLogger.instance.maxEntries = 1000; 

dio.interceptors.add(DioNetworkLogger());
```

### 3. Adding the UI Button
Place the `NetworkLoggerButton` in your Scaffold to access the logs:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('My App')),
    body: Center(child: Text('Content')),
    floatingActionButton: NetworkLoggerButton(),
  );
}
```

Alternatively, you can attach it globally as an **Overlay**:

```dart
void showLogger(BuildContext context) {
  NetworkLoggerOverlay.attachTo(context);
}
```

## Usage Tips

### 🔍 Deep Search
The search bar at the top isn't just for URLs. You can search for:
- **HTTP Methods**: Type `POST` or `GET` to filter by method.
- **Status Codes**: Type `404` or `500` to find specific responses.
- **JSON Content**: Type a key or value from your JSON request/response body.

### 🚥 Quick Filters
Use the filter chips below the search bar to instantly toggle visibility for:
- **Success (2xx)**: Only show successful requests.
- **Errors (4xx, 5xx)**: Only show failed requests or network errors.

### 🛠️ Exporting Data
- **cURL**: Tap the copy icon in the details view to get a ready-to-use cURL command (now supports `FormData`).
- **Full Session**: Tap the copy icon on the main logs screen to export your entire current session as a JSON array for bug reports.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

## License
[MIT](LICENSE)
