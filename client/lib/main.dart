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
  bool _isMicHighlighted = false;
  bool _isCalculationInProgress = false;
  bool _isCalculateClicked = false;

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
        _progressControllerBlue.repeat();
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
            if (_isFirstPress) {
              _isMicHighlighted = true;
              _isCalculationInProgress = false;
              _speechUtils.startRecording();
            } else {
              _isMicHighlighted = false;
              _isCalculationInProgress = true;
              _speechUtils.stopRecording();
              _progressControllerBlue.stop();
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
                  "Tap on the mic and say a math expression\n Or just press the 'Space' key",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _result = '';
                    });
                    _speechUtils.startRecording();
                  },
                  backgroundColor: Colors.blue,
                  shape: _isMicHighlighted 
                    ? const RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.red,
                         width: 3)) 
                    : null,
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
                            child: Text('Timer for the difference between two numbers'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // if(_isCalculateClicked)
                //   Text(
                //   _spokenText.isEmpty
                //       ? 'Nothing was said' //TODO: Need to implement after valida api response
                //       : 'You said: $_spokenText',
                //   style: const TextStyle(fontSize: 24),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _speechUtils.stopRecording();
                    _progressControllerBlue.stop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, color: Colors.white),
                    side: _isCalculationInProgress ? const BorderSide(color: Colors.red, width: 3) : BorderSide.none,
                  ),
                  child: const Text('Calculate'),
                ),
                const SizedBox(height: 30),
                Text(
                  _result.contains('Error')
                  ?'Error: Please try again' 
                  : 'Result: $_result',
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
