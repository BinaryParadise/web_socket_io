import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_io/web_socket_frame.dart';
import 'package:web_socket_io/web_socket_io.dart';

class ServerDemo implements WebSocketProvider {
  final WebSocketServer _server = WebSocketServer();
  ServerDemo() {
    _server.provider = this;
  }
  void play() {
    _server.bind('127.0.0.1', 10086);
  }

  void stop() {
    _server.close();
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
    print('onMessage: ${Utf8Decoder().convert(message)}');
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
