import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'dart:convert' as convert;

import 'web_socket_frame.dart';
import 'web_socket_io.dart';

/// TODO
class WebSocketServer {
  WebSocketProvider? provider;
  late ServerSocket _mainSocket;

  void bind(String address, int port) async {
    _mainSocket = await ServerSocket.bind(address, port);
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
                convert.Utf8Decoder().convert(frame.payload), channel);
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
            // TODO: Handle this case.
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
    var acceptKey = convert.base64
        .encode(sha1.convert((secretKey + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').codeUnits).bytes);
    channel.socket.write('HTTP/1.1 101 Switching Protocols\r\n');
    channel.socket.write('Upgrade: websocket\r\n');
    channel.socket.write('Connection: Upgrade\r\n');
    channel.socket.write('Sec-WebSocket-Accept: $acceptKey\r\n');
    channel.socket.write('\r\n');
    channel.handshaked = true;
    provider?.onConnected(channel);
  }

  @override
  Future<bool> close({CloseCode code = CloseCode.normal}) async {
    await _mainSocket.close();
    return Future.value(true);
  }
}
