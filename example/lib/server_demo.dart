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

const TextData = '''
WebSocket is a computer communications protocol, providing full-duplex communication channels over a single TCP connection. The WebSocket protocol was standardized by the IETF as RFC 6455 in 2011. The current API specification allowing web applications to use this protocol is known as WebSockets.[1] It is a living standard maintained by the WHATWG and a successor to The WebSocket API from the W3C.[2]
WebSocket is distinct from HTTP. Both protocols are located at layer 7 in the OSI model and depend on TCP at layer 4. Although they are different, RFC 6455 states that WebSocket "is designed to work over HTTP ports 443 and 80 as well as to support HTTP proxies and intermediaries", thus making it compatible with HTTP. To achieve compatibility, the WebSocket handshake uses the HTTP Upgrade header[3] to change from the HTTP protocol to the WebSocket protocol.
The WebSocket protocol enables interaction between a web browser (or other client application) and a web server with lower overhead than half-duplex alternatives such as HTTP polling, facilitating real-time data transfer from and to the server. This is made possible by providing a standardized way for the server to send content to the client without being first requested by the client, and allowing messages to be passed back and forth while keeping the connection open. In this way, a two-way ongoing conversation can take place between the client and the server. The communications are usually done over TCP port number 443 (or 80 in the case of unsecured connections), which is beneficial for environments that block non-web Internet connections using a firewall. Similar two-way browser–server communications have been achieved in non-standardized ways using stopgap technologies such as Comet or Adobe Flash Player.[4]
Most browsers support the protocol, including Google Chrome, Firefox, Microsoft Edge, Internet Explorer, Safari and Opera.[5]
Unlike HTTP, WebSocket provides full-duplex communication.[6][7] Additionally, WebSocket enables streams of messages on top of TCP. TCP alone deals with streams of bytes with no inherent concept of a message. Before WebSocket, port 80 full-duplex communication was attainable using Comet channels; however, Comet implementation is nontrivial, and due to the TCP handshake and HTTP header overhead, it is inefficient for small messages. The WebSocket protocol aims to solve these problems without compromising the security assumptions of the web.
The WebSocket protocol specification defines ws (WebSocket) and wss (WebSocket Secure) as two new uniform resource identifier (URI) schemes[8] that are used for unencrypted and encrypted connections respectively. Apart from the scheme name and fragment (i.e. # is not supported), the rest of the URI components are defined to use URI generic syntax.[9]
Using browser developer tools, developers can inspect the WebSocket handshake as well as the WebSocket frames.
''';

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
    _server.bind('0.0.0.0', 10086);
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
  void send(bool text) {
    if (text) {
      _sessions.values.forEach((element) =>
          element.send(OpCode.text, Uint8List.fromList(TextData.codeUnits)));
    } else {
      _sessions.values.forEach((element) =>
          element.send(OpCode.binary, Uint8List.fromList(TextData.codeUnits)));
    }
  }

  @override
  ValueNotifier<List<String>> valueListenable() {
    return _valueChanged;
  }
}
