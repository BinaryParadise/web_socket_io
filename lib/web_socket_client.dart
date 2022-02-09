import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'web_socket_frame.dart';
import 'web_socket_provider.dart';

class WebSocketClient implements WebSocketChannel {
  String url;
  Map<String, String>? headers;
  WebSocketProvider provider;
  Duration? pingInterval;
  WebSocketClient(this.url,
      {required this.provider, this.pingInterval, this.headers});

  bool _handshaked = false;
  Socket? _socket;

  Future<bool> connect() async {
    var uri = Uri.parse(url);
    await Socket.connect(uri.host, uri.port).then((value) {
      _socket = value;

      _socket?.listen((event) {
        if (_handshaked) {
          var frame = WebSocketFrame.create(event);
          switch (frame.opcode) {
            case OpCode.text:
              provider.onText(String.fromCharCodes(frame.payload), this);
              break;
            case OpCode.binary:
              provider.onMessage(frame.payload, this);
              break;
            case OpCode.close:
              provider.onClosed(CloseCodeExtension.parse(frame.payload.uint16));
              break;
            case OpCode.ping:
              // TODO: Handle this case.
              break;
            case OpCode.pong:
              // TODO: Handle this case.
              break;
            case OpCode.reserved:
              // TODO: Handle this case.
              break;
          }
        } else {
          var hds = String.fromCharCodes(event.toList()).split('\r\n');
          _handshaked = true;
          provider.onConnected(this);
          if (pingInterval != null) {
            Timer.periodic(pingInterval!, (timer) {});
          }
        }
      }, onError: (error) {
        provider.onClosed(CloseCode.error);
      });

      _socket?.writeln('GET ${uri.path} HTTP/1.1');
      _socket?.writeln('Host: ${uri.host}:${uri.port}');
      _socket?.writeln('Upgrade: websocket');
      _socket?.writeln('Connection: Upgrade');
      _socket?.writeln('Sec-WebSocket-Key: ${secKey()}');
      _socket?.writeln('Sec-WebSocket-Version: 13');
      _socket?.writeln(
          'Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits');
      headers?.forEach((key, value) {
        _socket?.writeln('$key: $value');
      });
      _socket?.writeln();
    }).catchError((error) => print(error));
    return true;
  }

  void sendBinary(List<int> data) {}

  void sendPing({List<int> data = const []}) {
    var frame = WebSocketFrame(OpCode.ping, payload: Uint8List.fromList(data));
    _socket?.add(frame.rawBytes());
  }

  @override
  void send(OpCode code, Uint8List data) {
    var frame = WebSocketFrame(code, mask: true, payload: data);
    var raw = frame.rawBytes();
    _socket?.add(raw.toList());
  }

  @override
  Future<bool> close({CloseCode code = CloseCode.normal}) {
    var frame =
        WebSocketFrame(OpCode.close, payload: 1006.bytes(bit: BitWidth.short));
    _socket?.add(frame.rawBytes());
    return Future.value(true);
  }

  String secKey() {
    List<int> d = List.filled(16, 0);
    var rand = Random();
    for (var i = 0; i < d.length; i++) {
      d[i] = rand.nextInt(255);
    }
    return convert.base64.encode(d);
  }
}
