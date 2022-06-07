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
简介
编辑
WebSocket是一种与HTTP不同的协议。两者都位于OSI模型的应用层，并且都依赖于传输层的TCP协议。 虽然它们不同，但是RFC 6455中规定：it is designed to work over HTTP ports 80 and 443 as well as to support HTTP proxies and intermediaries（WebSocket通过HTTP端口80和443进行工作，并支持HTTP代理和中介），从而使其与HTTP协议兼容。 为了实现兼容性，WebSocket握手使用HTTP Upgrade头[1]从HTTP协议更改为WebSocket协议。

WebSocket协议支持Web浏览器（或其他客户端应用程序）与Web服务器之间的交互，具有较低的开销，便于实现客户端与服务器的实时数据传输。 服务器可以通过标准化的方式来实现，而无需客户端首先请求内容，并允许消息在保持连接打开的同时来回传递。通过这种方式，可以在客户端和服务器之间进行双向持续对话。 通信通过TCP端口80或443完成，这在防火墙阻止非Web网络连接的环境下是有益的。另外，Comet之类的技术以非标准化的方式实现了类似的双向通信。

大多数浏览器都支持该协议，包括Google Chrome、Firefox、Safari、Microsoft Edge、Internet Explorer和Opera。

与HTTP不同，WebSocket提供全双工通信。[2][3]此外，WebSocket还可以在TCP之上实现消息流。TCP单独处理字节流，没有固有的消息概念。 在WebSocket之前，使用Comet可以实现全双工通信。但是Comet存在TCP握手和HTTP头的开销，因此对于小消息来说效率很低。WebSocket协议旨在解决这些问题。

WebSocket协议规范将ws（WebSocket）和wss（WebSocket Secure）定义为两个新的统一资源标识符（URI）方案[4]，分别对应明文和加密连接。除了方案名称和片段ID（不支持#）之外，其余的URI组件都被定义为此URI的通用语法。[5]

使用浏览器开发人员工具，开发人员可以检查WebSocket握手以及WebSocket框架。[6]

历史
编辑
WebSocket最初在HTML5规范中被引用为TCPConnection，作为基于TCP的套接字API的占位符。[7]2008年6月，Michael Carter（英语：Michael Carter (entrepreneur)）进行了一系列讨论，最终形成了称为WebSocket的协议。[8]

“WebSocket”这个名字是Ian Hickson和Michael Carter之后在 #whatwg IRC聊天室创造的[9]，随后由Ian Hickson撰写并列入HTML5规范，并在Michael Carter的Cometdaily博客上宣布[10]。 2009年12月，Google Chrome 4是第一个提供标准支持的浏览器，默认情况下启用了WebSocket。[11]WebSocket协议的开发随后于2010年2月从W3C和WHATWG小组转移到IETF，并在Ian Hickson的指导下进行了两次修订。[12]

该协议被多个浏览器默认支持并启用后，RFC于2011年12月在Ian Fette下完成。[13]

背景
编辑
早期，很多网站为了实现推送技术，所用的技术都是轮询。轮询是指由浏览器每隔一段时间（如每秒）向服务器发出HTTP请求，然后服务器返回最新的数据给客户端。这种传统的模式带来很明显的缺点，即浏览器需要不断的向服务器发出请求，然而HTTP请求与回复可能会包含较长的头部，其中真正有效的数据可能只是很小的一部分，所以这样会消耗很多带宽资源。

比较新的轮询技术是Comet。这种技术虽然可以实现双向通信，但仍然需要反复发出请求。而且在Comet中普遍采用的HTTP长连接也会消耗服务器资源。

在这种情况下，HTML5定义了WebSocket协议，能更好的节省服务器资源和带宽，并且能够更实时地进行通讯。

Websocket使用ws或wss的统一资源标志符（URI）。其中wss表示使用了TLS的Websocket。如：

ws://example.com/wsapi
wss://secure.example.com/wsapi
Websocket与HTTP和HTTPS使用相同的TCP端口，可以绕过大多数防火墙的限制。默认情况下，Websocket协议使用80端口；运行在TLS之上时，默认使用443端口。

优点
编辑
较少的控制开销。在连接建立后，服务器和客户端之间交换数据时，用于协议控制的数据包头部相对较小。在不包含扩展的情况下，对于服务器到客户端的内容，此头部大小只有2至10字节（和数据包长度有关）；对于客户端到服务器的内容，此头部还需要加上额外的4字节的掩码。相对于HTTP请求每次都要携带完整的头部，此项开销显著减少了。
更强的实时性。由于协议是全双工的，所以服务器可以随时主动给客户端下发数据。相对于HTTP请求需要等待客户端发起请求服务端才能响应，延迟明显更少；即使是和Comet等类似的长轮询比较，其也能在短时间内更多次地传递数据。
保持连接状态。与HTTP不同的是，Websocket需要先建立连接，这就使得其成为一种有状态的协议，之后通信时可以省略部分状态信息。而HTTP请求可能需要在每个请求都携带状态信息（如身份认证等）。
更好的二进制支持。Websocket定义了二进制帧，相对HTTP，可以更轻松地处理二进制内容。
可以支持扩展。Websocket定义了扩展，用户可以扩展协议、实现部分自定义的子协议。如部分浏览器支持压缩等。
更好的压缩效果。相对于HTTP压缩，Websocket在适当的扩展支持下，可以沿用之前内容的上下文，在传递类似的数据时，可以显著地提高压缩率。[14]
握手协议
编辑
WebSocket 是独立的、建立在TCP上的协议。

Websocket 通过 HTTP/1.1 协议的101状态码进行握手。

为了建立Websocket连接，需要通过浏览器发出请求，之后服务器进行回应，这个过程通常称为“握手”（Handshaking）。
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
      _sessions.values.forEach((element) => element.sendText(TextData));
    }
  }

  @override
  ValueNotifier<List<String>> valueListenable() {
    return _valueChanged;
  }
}
