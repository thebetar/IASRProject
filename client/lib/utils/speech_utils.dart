import 'dart:async';
import 'dart:html' as html;
import '../api/api_client.dart';

class SpeechUtils {
  final Function(String) updateCountDown;
  final Function(String) updateResult;
  final Function startAnimation;
  String _countDownText = '';
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];
  bool _isRecording = false;
  int _start = 5;
  Timer? _timer;
  late final ApiClient _apiClient;

  SpeechUtils({required this.updateCountDown, required this.updateResult, required this.startAnimation}) {
    _apiClient = ApiClient(updateResult);
  }

  Future<void> startRecording() async {
    try {
      _start = 5;
      _countDownText = '$_start';
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
        if (_start == 0) {
          _countDownText = 'Listening...';
          timer.cancel();

          html.MediaStream stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
          _mediaRecorder = html.MediaRecorder(stream);
          _mediaRecorder!.start();

          Timer.run(() {
            startAnimation(); // Start the animation
          });

          _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
            print('Data available event fired');
            if ((event as html.BlobEvent).data != null) {
              _audioChunks.add((event as html.BlobEvent).data!);
            }
          });

          _isRecording = true;
        } else {
          _start--;
          _countDownText = '$_start';
        }
        updateCountDown(_countDownText);
      });
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      _mediaRecorder!.addEventListener('stop', (html.Event event) {
        print('Recording stopped');

        print('Number of audio chunks: ${_audioChunks.length}');

        html.Blob audioBlob = html.Blob(_audioChunks, 'audio/wav');

        _apiClient.sendAudioToServer(audioBlob);

        _isRecording = false;
      });

      _mediaRecorder!.stop();
    } catch (e) {
      print('Failed to stop recording: $e'); //TODO: Remove this line after debugging
    }
  }
}