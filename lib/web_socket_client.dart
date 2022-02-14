import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:typed_data';

import 'web_socket_frame.dart';
import 'web_socket_provider.dart';

class WebSocketClient {
  String url;
  Map<String, String>? headers;
  WebSocketProvider provider;
  WebSocketClient(this.url, {required this.provider, this.headers});

  late WebSocketChannel _channel;

  Future<bool> connect() async {
    var uri = Uri.parse(url);
    var secretKey = secKey();
    var socket = await Socket.connect(uri.host, uri.port);
    _channel = WebSocketChannel(socket, mask: true);
    socket.listen((event) {
      if (_channel.handshaked) {
        var frame = WebSocketFrame.create(event);
        switch (frame.opcode) {
          case OpCode.text:
            provider.onText(String.fromCharCodes(frame.payload), _channel);
            break;
          case OpCode.binary:
            provider.onMessage(frame.payload, _channel);
            break;
          case OpCode.close:
            provider.onClosed(
                CloseCodeExtension.parse(frame.payload.uint16), _channel);
            break;
          case OpCode.ping:
            provider.onPing(frame.payload, _channel);
            break;
          case OpCode.pong:
            provider.onPong(frame.payload, _channel);
            break;
          case OpCode.reserved:
            // TODO: Handle this case.
            break;
        }
      } else {
        var secAcceptKey = String.fromCharCodes(event.toList())
            .split('\r\n')
            .firstWhere(
                (element) => element.startsWith('Sec-Websocket-Accept: '),
                orElse: () => '')
            .split(': ')
            .last;
        var expectKey = convert.base64.encoder.convert(sha1
            .convert(
                (secretKey + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').codeUnits)
            .bytes);
        if (secAcceptKey == expectKey) {
          _channel.handshaked = true;
          provider.onConnected(_channel);
        } else {
          provider.onClosed(CloseCode.protocol_error, _channel);
        }
      }
    }, onError: (error) {
      provider.onClosed(CloseCode.error, _channel);
    }, onDone: () {
      socket.destroy();
      provider.onClosed(CloseCode.normal, _channel);
    });

    socket.write('GET ${uri.path} HTTP/1.1\r\n');
    socket.write('Host: ${uri.host}:${uri.port}\r\n');
    socket.write('Upgrade: websocket\r\n');
    socket.write('Connection: Upgrade\r\n');
    socket.write('Sec-WebSocket-Key: $secretKey\r\n');
    socket.write('Sec-WebSocket-Version: 13\r\n');
    socket.write(
        'Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits\r\n');
    headers?.forEach((key, value) {
      socket.write('$key: $value\r\n');
    });
    socket.write('\r\n');
    return true;
  }

  void sendText(String text) {
    _channel.send(OpCode.text, const convert.Utf8Encoder().convert(text));
  }

  void sendData(Uint8List data) {
    _channel.send(OpCode.binary, data);
  }

  void sendPing(Uint8List data) {
    _channel.send(OpCode.ping, data);
  }

  Future<bool> close({CloseCode code = CloseCode.normal}) async {
    return await _channel.close(code: code);
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
