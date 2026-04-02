# Custom Network Logger

A lightweight, powerful network logging UI for Flutter applications using the **Dio** HTTP client. It captures all your network traffic and provides a beautiful, searchable overlay for inspection and debugging.

## Features
- 🚀 **One-Tap Integration**: Easily add as a Dio interceptor.
- 🔍 **Real-time Inspection**: Drill down into requests, responses, headers, and errors.
- ✨ **Searchable Logs**: Quickly filter your API calls by URL.
- 🛠️ **cURL Export**: Copy request details as cURL commands with a single click.
- 📱 **Draggable Overlay**: Access the logger from anywhere in your app with a floating button.

## Getting Started

### 1. Installation
Add `network_logger_custom` to your `pubspec.yaml`:
```yaml
dependencies:
  network_logger_custom: ^1.0.0
```

### 2. Basic Setup
Add the `DioNetworkLogger` interceptor to your Dio instance:

```dart
import 'package:dio/dio.dart';
import 'package:network_logger_custom/network_logger_custom.dart';

final dio = Dio();
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

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

## License
[MIT](LICENSE)
