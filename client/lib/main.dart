import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/speech_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final AnimationController _progressControllerBlue;
  late final AnimationController _progressControllerRed;
  late final AnimationController _progressControllerPurple;
  late final SpeechUtils _speechUtils;
  String _countDownText = '';
  String _result = '';
  String _spokenText = '';
  bool _isFirstPress = true;
  bool _isMicHighlighted = true;

  @override
  void initState() {
    super.initState();
    _progressControllerBlue = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    _progressControllerRed = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    _progressControllerPurple = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    _speechUtils = SpeechUtils(
      updateCountDown: (countDownText) {
        setState(() {
          _countDownText = countDownText;
        });
      },
      updateResult: (result) {
        setState(() {
          _result = result;
        });
      },
      startAnimation: () async {
        _progressControllerBlue.reset();
        await _progressControllerBlue.forward();
        _progressControllerRed.reset();
        await _progressControllerRed.forward();
        _progressControllerPurple.reset();
        await _progressControllerPurple.forward();
      },
    );
  }

  @override
  void dispose() {
    _progressControllerBlue.dispose();
    _progressControllerRed.dispose();
    _progressControllerPurple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction(
          onInvoke: (e) {
            print('Space pressed');
            if (_isFirstPress) {
              _speechUtils.startRecording();
              _isMicHighlighted = true;
            } else {
              _speechUtils.stopRecording();
              _isMicHighlighted = false;
            }
            _isFirstPress = !_isFirstPress;
            setState(() {});
          },
        ),
      },
      child: Scaffold(
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
                  onPressed: () {
                    _speechUtils.startRecording();
                  },
                  backgroundColor:
                      _isMicHighlighted ? Colors.blue : Colors.grey,
                  child: const Icon(Icons.mic),
                ),
                const SizedBox(height: 10),
                Text(
                  _countDownText,
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          LinearProgressIndicator(
                            value: _progressControllerBlue.value,
                            color: Colors.blue,
                            backgroundColor: Colors.blue.shade100,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Center(
                              child: Text('First number'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          LinearProgressIndicator(
                            value: _progressControllerRed.value,
                            color: Colors.red,
                            backgroundColor: Colors.red.shade100,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Center(
                              child: Text('Symbol'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          LinearProgressIndicator(
                            value: _progressControllerPurple.value,
                            color: Colors.purple,
                            backgroundColor: Colors.purple.shade100,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Center(
                              child: Text('Last number'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _spokenText.isEmpty
                      ? 'Your response is not processed yet'
                      : 'You said: $_spokenText', //TODO: Need to implement after API integration
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _speechUtils.stopRecording();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isMicHighlighted ? Colors.grey : Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('Calculate'),
                ),
                const SizedBox(height: 30),
                Text(
                  'Result: $_result',
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
