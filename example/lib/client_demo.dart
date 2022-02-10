import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:example/server_demo.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_io/web_socket_io.dart';

class ClientDemo implements WebSocketProvider, SocketDemoChannel {
  late WebSocketClient _client;
  late ValueNotifier<List<String>> _valueChanged;
  Timer? _pingTimer;

  ClientDemo() {
    _client = WebSocketClient('ws://127.0.0.1:10086', provider: this);
    _valueChanged = ValueNotifier<List<String>>([]);
  }

  @override
  Future<bool> play() async {
    return _client.connect();
  }

  @override
  Future<bool> stop() async {
    return await _client.close();
  }

  @override
  void send(bool text) {
    if (text) {
      _client.sendText('文本测试消息');
    } else {
      _client.sendData(const Utf8Encoder().convert('二进制测试消息'));
    }
  }

  @override
  void onClosed(CloseCode code, WebSocketChannel webSocket) {
    print('client.onClosed: $code');
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  @override
  void onConnected(WebSocketChannel webSocket) {
    print('client.onConnected');

    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _client.sendPing(
          const Utf8Encoder().convert(DateTime.now().toString()));
    });
  }

  @override
  void onText(String message, WebSocketChannel webSocket) {
    print('client.onText: $message');
    _valueChanged.value.add(message);
    _valueChanged.notifyListeners();
  }

  @override
  void onMessage(Uint8List message, WebSocketChannel webSocket) {
    print('client.onMessage: ${String.fromCharCodes(message)}');
    _valueChanged.value.add(const Utf8Decoder().convert(message));
    _valueChanged.notifyListeners();
  }

  @override
  void onPing(Uint8List data, WebSocketChannel webSocket) {
    print('client.onPing: ${const Utf8Decoder().convert(data)}');
  }

  @override
  void onPong(Uint8List data, WebSocketChannel webSocket) {
    print('client.onPong: ${const Utf8Decoder().convert(data)}');
  }

  @override
  ValueNotifier<List<String>> valueListenable() {
    return _valueChanged;
  }
}
