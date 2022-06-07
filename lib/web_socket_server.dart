import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'dart:convert' as convert;

import 'web_socket_frame.dart';
import 'web_socket_io.dart';

/// 服务端对象
class WebSocketServer {
  WebSocketProvider? provider;
  late ServerSocket _mainSocket;

  void bind(String address, int port) async {
    _mainSocket = await ServerSocket.bind(address, port);
    print('bind on $address:$port');
    _mainSocket.listen((newSocket) {
      _schedule(newSocket);
    });
  }

  void _schedule(Socket newSocket) {
    var channel = WebSocketChannel(newSocket);
    newSocket.listen((event) {
      if (channel.handshaked) {
        var frame = WebSocketFrame.create(event);
        switch (frame.opcode) {
          case OpCode.text:
            provider?.onText(
                const convert.Utf8Decoder().convert(frame.payload), channel);
            break;
          case OpCode.binary:
            provider?.onMessage(frame.payload, channel);
            break;
          case OpCode.close:
            channel.close().then((value) {
              provider?.onClosed(
                  CloseCodeExtension.parse(frame.payload.uint16), channel);
            });
            break;
          case OpCode.ping:
            provider?.onPing(frame.payload, channel);
            break;
          case OpCode.pong:
            provider?.onPong(frame.payload, channel);
            break;
          case OpCode.reserved:
            break;
        }
      } else {
        handshake(event, channel);
      }
    });
  }

  void handshake(Uint8List data, WebSocketChannel channel) {
    var secretKey = String.fromCharCodes(data.toList())
        .split('\r\n')
        .firstWhere((element) => element.contains('Sec-WebSocket-Key: '))
        .split(': ')
        .last;
    var acceptKey = convert.base64.encode(sha1
        .convert((secretKey + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').codeUnits)
        .bytes);
    var head = '''HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: $acceptKey

''';
    channel.socket.write(head);
    channel.handshaked = true;
    provider?.onConnected(channel);
  }

  Future<bool> close({CloseCode code = CloseCode.normal}) async {
    await _mainSocket.close();
    return Future.value(true);
  }
}
