
用Flutter实现的WebSocket轮子。

## WebSocket协议

> 请求握手
>
> `Sec-WebSocket-Key` = toBase64(16字节随机数)
```http
GET / HTTP/1.1
Host: 127.0.0.1:10086
Connection: Upgrade
Upgrade: websocket
Sec-WebSocket-Key: k8ZJD7PN3mwawWDsd9V1OA==
Sec-WebSocket-Version: 13
Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits
```

> 握手响应
>
> `Sec-WebSocket-Accept` = **toBase64**( **sha1**( **Sec**-**WebSocket**-**Key** + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" )  )

```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: WhwAE9ive8GXOhTDu6RlEunn4C0=
```

## 如何使用

### 服务端

```dart
class ServerDemo {
  final WebSocketServer _server = WebSocketServer();
  ServerDemo() {
    _server.onMessage = (event) {
      print(Utf8Decoder().convert(event.toList()));
    };
  }
  void play() {
    _server.bind('127.0.0.1', 10086);
  }

  void stop() {
    _server.close();
  }
}
```

### 客户端

```dart
class ClientDemo extends WebSocketProvider {
  late WebSocketClient _client;
  ClientDemo() {
    _client = WebSocketClient('ws://127.0.0.1:10086',
        provider: this, pingInterval: const Duration(seconds: 5));
    _client.connect();
  }

  void send(bool text) {
    if (text) {
      _client.send(OpCode.text, Uint8List.fromList('文本测试消息'.codeUnits));
    } else {
      _client.send(
          text ? OpCode.text : OpCode.binary, Utf8Encoder().convert('二进制测试消息'));
    }
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
    print('onMessage: ${String.fromCharCodes(message)}');
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
```

## TODO

- [ ] Ping、Pong