import 'dart:typed_data';

import 'package:web_socket_io/web_socket_frame.dart';

abstract class WebSocketChannel {
  void send(OpCode code, Uint8List data);
  Future<bool> close({CloseCode code = CloseCode.normal});
}

abstract class WebSocketProvider {
  void onConnected(WebSocketChannel webSocket);
  void onText(String message, WebSocketChannel webSocket);
  void onMessage(Uint8List message, WebSocketChannel webSocket);
  void onPing(Uint8List data, WebSocketChannel webSocket);
  void onPong(Uint8List data, WebSocketChannel webSocket);
  void onClosed(CloseCode code);
}
