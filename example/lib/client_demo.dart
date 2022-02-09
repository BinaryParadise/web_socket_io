import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_io/web_socket_frame.dart';
import 'package:web_socket_io/web_socket_io.dart';

class ClientDemo extends WebSocketProvider {
  late WebSocketClient _client;
  ClientDemo() {
    _client = WebSocketClient('ws://127.0.0.1:10086',
        provider: this, pingInterval: const Duration(seconds: 5));
  }

  void play() {
    _client.connect();
  }

  void stop() {
    _client.close();
  }

  void send(bool text) {
    if (text) {
      _client.send(OpCode.text, Utf8Encoder().convert('文本测试消息'));
    } else {
      _client.send(OpCode.binary, Utf8Encoder().convert('二进制测试消息'));
    }
  }

  @override
  void onClosed(CloseCode code) {
    print('onClosed: $code');
  }

  @override
  void onConnected(WebSocketChannel webSocket) {
    print('onConnected');
  }

  @override
  void onText(String message, WebSocketChannel webSocket) {
    print('onText: $message');
  }

  @override
  void onMessage(Uint8List message, WebSocketChannel webSocket) {
    print('onMessage: ${String.fromCharCodes(message)}');
  }

  @override
  void onPing(Uint8List data, WebSocketChannel webSocket) {
    print('onPing');
  }

  @override
  void onPong(Uint8List data, WebSocketChannel webSocket) {
    print('onPong');
  }
}
