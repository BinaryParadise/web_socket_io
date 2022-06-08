import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:web_socket_io/web_socket_frame.dart';

class WebSocketChannel {
  final Socket socket;
  bool mask;
  bool handshaked = false;
  WebSocketChannel(this.socket, {this.mask = false});

  void send(OpCode code, Uint8List data) {
    var frame = WebSocketFrame(code, mask: mask, payload: data);
    var raw = frame.rawBytes();
    socket.add(raw.toList());
  }

  void sendText(String text) {
    var frame = WebSocketFrame(OpCode.text, mask: mask, payload: Uint8List(0));
    var raw = frame.rawTextBytes(text.codeUnits);
    socket.add(raw.toList());
  }

  Future<bool> close({CloseCode code = CloseCode.normal, String message = ''}) {
    var bytes = BytesBuilder();
    bytes.add(code.value.bytes(bit: BitWidth.short).toList());
    bytes.add(const Utf8Encoder().convert(message).toList());
    send(OpCode.close, bytes.toBytes());
    return Future.value(true);
  }
}

abstract class WebSocketProvider {
  void onConnected(WebSocketChannel webSocket);
  void onText(String message, WebSocketChannel webSocket);
  void onMessage(Uint8List message, WebSocketChannel webSocket);
  void onPing(Uint8List data, WebSocketChannel webSocket);
  void onPong(Uint8List data, WebSocketChannel webSocket);
  void onClosed(CloseCode code, WebSocketChannel webSocket);
}
