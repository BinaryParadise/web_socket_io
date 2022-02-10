import 'package:example/client_demo.dart';
import 'package:flutter/material.dart';

import 'server_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ServerDemo _server;
  late ClientDemo _client;
  bool _serverRunning = false;
  bool _clientRunning = false;

  @override
  void initState() {
    _server = ServerDemo();
    _client = ClientDemo();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(child: _WorkPanel('服务端', ServerDemo())),
          Expanded(child: _WorkPanel('客户端', ClientDemo())),
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _WorkPanel extends StatefulWidget {
  String title;
  SocketDemoChannel channel;
  _WorkPanel(this.title, this.channel);
  @override
  State<_WorkPanel> createState() => _WorkPanelState();
}

class _WorkPanelState extends State<_WorkPanel> {
  var _running = false;
  ScrollController _controller = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget current;
    current = Row(
      children: [
        SizedBox(
          width: 12,
        ),
        Text(widget.title),
        IconButton(
            onPressed: () {
              if (_running) {
                widget.channel.stop().then((value) {
                  setState(() {
                    _running = false;
                  });
                });
              } else {
                widget.channel.play().then((value) {
                  setState(() {
                    _running = true;
                  });
                });
              }
            },
            icon: Icon(_running ? Icons.stop : Icons.play_circle_fill)),
        TextButton(
            onPressed: () {
              widget.channel.send(true);
            },
            child: const Text(
              '发送文本消息',
              style: TextStyle(color: Colors.orange),
            )),
        TextButton(
            onPressed: () {
              widget.channel.send(false);
            },
            child: const Text('发送二进制消息'))
      ],
    );
    Widget list = ValueListenableBuilder(
        valueListenable: widget.channel.valueListenable(),
        builder: (ctx, List<String> value, widget) {
          Future.delayed(const Duration(microseconds: 200), () {
            _controller.jumpTo(_controller.position.maxScrollExtent);
          });
          return ListView.builder(
              shrinkWrap: true,
              controller: _controller,
              padding: const EdgeInsets.all(10),
              itemBuilder: (ctx, row) => Text(value[row]),
              itemCount: value.length);
        });
    current = Column(
      children: [current, Expanded(child: list)],
    );
    return current;
  }
}
