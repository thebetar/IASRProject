import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import '../api/api_client.dart';

class SpeechUtils {
  late stt.SpeechToText _speech;
  String _spokenText = '';
  String _countDownText = '';
  Timer? _timer;
  int _start = 5;

  final ApiClient _apiClient;

  SpeechUtils(this._apiClient) {
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool isAvailable = await _speech.initialize();
    if (!isAvailable) {
      // Handle speech initialization failure
      print('Speech initialization failed.'); // Todo: remove this line after testing
      // You can display an error message or take appropriate action
    }
  }

  void _reset() {
    _spokenText = '';
  }

  void startTimer(void Function() onListen, void Function(String countDownText) onCountDown) {
    if (_speech.isListening) {
      _speech.stop();
      _reset();
      return;
    }
    _reset();
    _countDownText = '5';
    _start = 5;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        _countDownText = 'Go!';
        timer.cancel();
        onListen();
      } else {
        _countDownText = '$_start';
        _start--;
      }
      onCountDown(_countDownText);
    });
  }

  void listen(void Function(String spokenText) onResult) {
    if (_speech.isListening) {
      _speech.stop();
    }
    _speech.listen(onResult: (val) {
      _spokenText = val.recognizedWords;
      _countDownText = '';
      _start = 3;
      onResult(_spokenText);
    });
  }

  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }

  void calculate(void Function(String result) onCalculate) async {
    if (_speech.isListening) {
      _speech.stop();
    }
    try {
      final result = await _apiClient.calculate(_spokenText);
      onCalculate(result);
    } catch (e) {
      // Handle API call error
      print('API call failed: $e'); // Todo: remove this line after testing
      // You can display an error message or take appropriate action
    }
  }

  void dispose() {
    _timer?.cancel(); // Make sure to cancel the timer when the utility is disposed
  }
}
