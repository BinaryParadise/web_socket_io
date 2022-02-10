import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_io/web_socket_frame.dart';
import 'package:web_socket_io/web_socket_io.dart';

abstract class SocketDemoChannel {
  Future<bool> play();

  Future<bool> stop();

  void send(bool text);

  ValueNotifier<List<String>> valueListenable();
}

class ServerDemo implements WebSocketProvider, SocketDemoChannel {
  final Map<int, WebSocketChannel> _sessions = {};
  final WebSocketServer _server = WebSocketServer();
  late ValueNotifier<List<String>> _valueChanged;

  ServerDemo() {
    _server.provider = this;
    _valueChanged = ValueNotifier<List<String>>([]);
  }
  @override
  Future<bool> play() async {
    _server.bind('127.0.0.1', 10086);
    return Future.value(true);
  }

  @override
  Future<bool> stop() async {
    return await _server.close();
  }

  @override
  void onClosed(CloseCode code, WebSocketChannel webSocket) {
    print('server.onClosed: $code');
    _sessions.remove(webSocket.hashCode);
  }

  @override
  void onConnected(WebSocketChannel webSocket) {
    print('server.onConnected');
    _sessions[webSocket.hashCode] = webSocket;
  }

  @override
  void onText(String message, WebSocketChannel webSocket) {
    print('server.onText: $message');
    _valueChanged.value.add(message);
    _valueChanged.notifyListeners();
  }

  @override
  void onMessage(Uint8List message, WebSocketChannel webSocket) {
    print('server.onMessage: ${Utf8Decoder().convert(message)}');
    _valueChanged.value.add(Utf8Decoder().convert(message));
    _valueChanged.notifyListeners();
  }

  @override
  void onPing(Uint8List data, WebSocketChannel webSocket) {
    print('server.onPing: ${Utf8Decoder().convert(data)}');
    webSocket.send(
        OpCode.pong, const Utf8Encoder().convert(DateTime.now().toString()));
  }

  @override
  void onPong(Uint8List data, WebSocketChannel webSocket) {
    print('server.onPong: ${Utf8Decoder().convert(data)}');
  }

  @override
  void send(bool text) {}

  @override
  ValueNotifier<List<String>> valueListenable() {
    return _valueChanged;
  }
}
