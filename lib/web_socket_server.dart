import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'dart:convert' as convert;

import 'web_socket_frame.dart';
import 'web_socket_io.dart';

const String webSocketGUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

/// TODO
class WebSocketServer implements WebSocketChannel {
  final Map<int, Socket> _sessions = {};
  WebSocketProvider? provider;
  late ServerSocket _mainSocket;

  void bind(String address, int port) async {
    var mainSocket = await ServerSocket.bind(address, port);
    mainSocket.listen((newSocket) {
      newSocket.listen((event) {
        if (_sessions.containsKey(newSocket.hashCode)) {
          var frame = WebSocketFrame.create(event);
          switch (frame.opcode) {
            case OpCode.text:
              provider?.onText(
                  convert.Utf8Decoder().convert(frame.payload), this);
              break;
            case OpCode.binary:
              provider?.onMessage(frame.payload, this);
              break;
            case OpCode.close:
              provider
                  ?.onClosed(CloseCodeExtension.parse(frame.payload.uint16));
              break;
            case OpCode.ping:
              provider?.onPing(frame.payload, this);
              break;
            case OpCode.pong:
              provider?.onPing(frame.payload, this);
              break;
            case OpCode.reserved:
              // TODO: Handle this case.
              break;
          }
        } else {
          handshake(event, newSocket);
        }
      });
    });
    _mainSocket = mainSocket;
  }

  void handshake(Uint8List data, Socket socket) {
    var secretKey = String.fromCharCodes(data.toList())
        .split('\r\n')
        .firstWhere((element) => element.contains('Sec-WebSocket-Key'))
        .split(': ')
        .last;
    var acceptKey = convert.base64
        .encode(sha1.convert((secretKey + webSocketGUID).codeUnits).bytes);
    socket.writeln('HTTP/1.1 101 Switching Protocols');
    socket.writeln('Upgrade: websocket');
    socket.writeln('Connection: Upgrade');
    socket.writeln('Sec-WebSocket-Accept: $acceptKey');
    socket.writeln();
    _sessions[socket.hashCode] = socket;
  }

  @override
  Future<bool> close({CloseCode code = CloseCode.normal}) async {
    _sessions.forEach((key, value) {
      var frame = WebSocketFrame(OpCode.close,
          payload: code.value.bytes(bit: BitWidth.short));
      value.add(frame.rawBytes().toList());
    });
    await _mainSocket.close();
    return Future.value(true);
  }

  @override
  void send(OpCode code, Uint8List data) {
    // TODO: implement send
  }
}
