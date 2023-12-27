import 'package:flutter/material.dart';
import 'package:voice_calculator_flutter/utils/speech_utils.dart';
import 'api/api_client.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Calculator',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SpeechUtils _speechUtils;
  String _countDownText = '';
  String _result = '';
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _speechUtils = SpeechUtils(ApiClient());
  }

  void _startTimer() {
    _speechUtils.startTimer(() {
      setState(() {
        _listen();
      });
    }, (countDownText) {
      setState(() {
        _countDownText = countDownText;
      });
    });
  }

  void _listen() {
    _speechUtils.listen((spokenText) {
      setState(() {
        _spokenText = spokenText;
      });
    });
  }

  void _calculate() {
    _speechUtils.calculate((result) {
      setState(() {
        _result = result;
      });
    });
  }

  @override
  void dispose() {
    _speechUtils.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Calculator"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Tap on the mic and say a math expression',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              FloatingActionButton(
                onPressed: _startTimer,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.mic),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  _countDownText,
                  key: ValueKey<String>(_countDownText),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _spokenText.isEmpty ? 'You have not said anything yet' : 'You said: $_spokenText',
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Calculate'),
              ),
              const SizedBox(height: 30),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Result: $_result',
                  key: ValueKey<String>(_result),
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}