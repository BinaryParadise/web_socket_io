import 'dart:math';
import 'dart:typed_data';

class WebSocketFrame {
  /// 是否最后一个分片
  bool fin = true;
  OpCode opcode = OpCode.text;
  bool mask = false;
  bool valid = true;
  int length = 0;
  Uint8List? maskingKey;
  Uint8List payload = Uint8List(0);

  /// 粘包处理
  static BytesBuilder buffer = BytesBuilder();

  WebSocketFrame.create(Uint8List data) {
    WebSocketFrame.buffer.add(data.toList());
    var stream = WebSocketFrame.buffer.toBytes();
    var index = 0;
    var head = stream.first;
    index += 1;
    fin = head & 0x80 != 0;
    opcode = OpCodeExtension.parse(head & opCodeMask);

    valid = isValid(head);

    var second = stream[index];
    index += 1;

    mask = second & maskMask != 0;

    var payloadLen = second & payloadLenMask;

    if (payloadLen < 126) {
      length = payloadLen;
    } else if (payloadLen == 126) {
      length = Uint8List.fromList(stream.getRange(index, index + 2).toList())
          .buffer
          .asByteData()
          .getUint16(0);
      index += 2;
    } else {
      length = Uint8List.fromList(stream.getRange(index, index + 4).toList())
          .buffer
          .asByteData()
          .getUint16(0);
      index += 4;
    }
    if (mask) {
      maskingKey =
          Uint8List.fromList(stream.getRange(index, index + 4).toList());
      index += 4;
    }

    if (valid) {
      payload =
          Uint8List.fromList(stream.getRange(index, index + length).toList());
      if (maskingKey != null) {
        //反掩码
        for (var i = 0; i < payload.length; i++) {
          payload[i] = payload[i] ^ maskingKey![i % 4];
        }
      }
    }
    WebSocketFrame.buffer.clear();
  }

  WebSocketFrame(this.opcode, {required this.payload, this.mask = true});

  Uint8List rawBytes() {
    var bytes = BytesBuilder();
    var head = 0;
    if (fin) {
      head |= 0x80;
    }
    head |= opcode.value & opCodeMask;
    bytes.addByte(head);
    length = payload.length;
    if (length < 126) {
      bytes.addByte(payload.length.bytes(bit: BitWidth.byte).first |
          (mask ? maskMask : 0x00));
    } else if (length <= 65535) {
      bytes.addByte(0x7E | (mask ? maskMask : 0x00));
      bytes.add(payload.length.bytes(bit: BitWidth.short).toList());
    } else {
      bytes.addByte(0x7F | (mask ? maskMask : 0x00));
      bytes.add(payload.length.bytes(bit: BitWidth.long).toList());
    }

    var data = payload;
    if (mask) {
      maskingKey = Random().nextInt(4294967295).bytes();
      bytes.add(maskingKey!.toList());

      for (var i = 0; i < data.length; i++) {
        data[i] = data[i] ^ maskingKey![i % 4];
      }
    }

    bytes.add(data.toList());
    return bytes.toBytes();
  }

  Uint8List rawTextBytes(List<int> payload) {
    var bytes = BytesBuilder();
    var head = 0;
    if (fin) {
      head |= 0x80;
    }
    head |= opcode.value & opCodeMask;
    bytes.addByte(head);
    length = payload.length;
    if (length < 126) {
      bytes.addByte(payload.length.bytes(bit: BitWidth.byte).first |
          (mask ? maskMask : 0x00));
    } else if (length <= 65535) {
      bytes.addByte(0x7E | (mask ? maskMask : 0x00));
      bytes.add(payload.length.bytes(bit: BitWidth.short).toList());
    } else {
      bytes.addByte(0x7F | (mask ? maskMask : 0x00));
      bytes.add(payload.length.bytes(bit: BitWidth.long).toList());
    }

    var data = payload;
    if (mask) {
      maskingKey = Random().nextInt(4294967295).bytes();
      bytes.add(maskingKey!.toList());

      for (var i = 0; i < data.length; i++) {
        data[i] = data[i] ^ maskingKey![i % 4];
      }
    }

    bytes.add(data.toList());
    return bytes.toBytes();
  }

  static bool isValid(int head) {
    var rsv = head & rsvMask;
    var opcode = head & opCodeMask;
    if (rsv != 0 ||
        (3 <= opcode && opcode <= 7) ||
        (0xB <= opcode && opcode <= 0xF)) {
      return false;
    }
    return true;
  }
}

enum BitWidth { byte, short, int, long }

extension BiWithExt on BitWidth {
  static List<int> bits = [8, 16, 32, 64];

  int get value {
    return bits[index];
  }
}

extension IntExtension on int {
  Uint8List bytes({BitWidth bit = BitWidth.int}) {
    var data = createUint8ListFromHexString(toRadixString(16).padLeft(16, '0'));
    return Uint8List.fromList(data
        .getRange(data.length - (bit.value / 8).round(), data.length)
        .toList());
  }

  /// Creates a `Uint8List` by a hex string.
  static Uint8List createUint8ListFromHexString(String hex) {
    var result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var num = hex.substring(i, i + 2);
      var byte = int.parse(num, radix: 16);
      result[i ~/ 2] = byte;
    }

    return result;
  }

  /// Returns a hex string by a `Uint8List`.
  static String formatBytesAsHexString(Uint8List bytes) {
    var result = StringBuffer();
    for (var i = 0; i < bytes.lengthInBytes; i++) {
      var part = bytes[i];
      result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }

    return result.toString();
  }
}

extension Uint8ListExt on Uint8List {
  int get uint16 {
    return length > 1 ? ((this[0] & 0xFF) << 8) + (this[1] & 0xFF) : 0;
  }

  String toHex() {
    if (length == 0) {
      return "";
    }
    Uint8List result = Uint8List(length << 1);
    var hexTable = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F'
    ]; //16进制字符表
    for (var i = 0; i < length; i++) {
      var bit = this[i]; //取传入的byteArr的每一位
      var index = bit >> 4 & 15; //右移4位,取剩下四位
      var i2 = i << 1; //byteArr的每一位对应结果的两位,所以对于结果的操作位数要乘2
      result[i2] = hexTable[index].codeUnitAt(0); //左边的值取字符表,转为Unicode放进resut数组
      index = bit & 15; //取右边四位
      result[i2 + 1] =
          hexTable[index].codeUnitAt(0); //右边的值取字符表,转为Unicode放进resut数组
    }
    return String.fromCharCodes(result); //Unicode转回为对应字符,生成字符串返回
  }
}

const int opCodeMask = 0x0F;
const int rsvMask = 0x70;
const int maskMask = 0x80;
const int payloadLenMask = 0x7F;

enum OpCode {
  text,
  binary,
  // 3-7 reserved.
  close,
  ping,
  pong,
  // B-F reserved.
  reserved
}

enum CloseCode {
  normal, //	正常关闭; 无论为何目的而创建, 该链接都已成功完成任务.
  goaway, //	终端离开, 可能因为服务端错误, 也可能因为浏览器正从打开连接的页面跳转离开.
  protocolError, //由于协议错误而中断连接.
  unsupported, //由于接收到不允许的数据类型而断开连接 (如仅接收文本数据的终端接收到了二进制数据).
  unsupportedData, //由于收到了格式不符的数据而断开连接 (如文本消息中包含了非 UTF-8 数据).
  policyViolation, //由于收到不符合约定的数据而断开连接. 这是一个通用状态码, 用于不适合使用 1003 和 1009 状态码的场景.
  tooLarge, //由于收到过大的数据帧而断开连接.
  missingExtension, //客户端期望服务器商定一个或多个拓展, 但服务器没有处理, 因此客户端断开连接.
  error, //客户端由于遇到没有预料的情况阻止其完成请求, 因此服务端断开连接.
  restart, //Service Restart	服务器由于重启而断开连接. [Ref]
  tryAgainLater, //服务器由于临时原因断开连接, 如服务器过载因此断开一部分客户端连接. [Ref]
  tlsHandshake, //保留. 表示连接由于无法完成 TLS 握手而关闭 (例如无法验证服务器证书).
  reserved
}

extension CloseCodeExtension on CloseCode {
  static List<int> codes = [
    1000,
    1001,
    1002,
    1003,
    1005,
    1006,
    1007,
    1008,
    1009,
    1010,
    1011,
    1012,
    1013,
    1014,
    1015
  ];

  int get value {
    return codes[index];
  }

  static CloseCode parse(int value) {
    var index = codes.indexOf(value);
    return index < 0 ? CloseCode.reserved : CloseCode.values[index];
  }
}

extension OpCodeExtension on OpCode {
  static const List<int> codes = [0x1, 0x2, 0x8, 0x9, 0xA];
  int get value {
    return codes[index];
  }

  static OpCode parse(int value) {
    var idx = codes.indexOf(value);
    return idx < 0 ? OpCode.reserved : OpCode.values[idx];
  }
}
