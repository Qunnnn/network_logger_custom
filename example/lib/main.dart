import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:network_logger_custom/network_logger_custom.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Logger Demo',
      theme: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    // Add the network logger interceptor
    _dio.interceptors.add(DioNetworkLogger());
  }

  Future<void> _makeRequest() async {
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      await _dio.post('https://jsonplaceholder.typicode.com/posts', data: {
        'title': 'foo',
        'body': 'bar',
        'userId': 1,
      });
      // Trigger an error
      await _dio.get('https://jsonplaceholder.typicode.com/invalid-url');
    } catch (e) {
      // Error is caught and logged by the interceptor
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Logger Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Press the button to make network requests:',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _makeRequest,
              child: const Text('Make Requests'),
            ),
          ],
        ),
      ),
      floatingActionButton: NetworkLoggerButton(),
    );
  }
}
