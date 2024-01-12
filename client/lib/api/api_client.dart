import 'dart:html' as html;
import 'dart:convert' as convert;

class ApiClient {
  final Function(String) updateResult;

  ApiClient(this.updateResult);

  void sendAudioToServer(html.Blob audioBlob) {
    try {
      var formData = html.FormData();
      formData.appendBlob('file', audioBlob);

      var request = html.HttpRequest();
      request.open('POST', 'http://localhost:5000/calculate');
      request.send(formData);

      request.onLoadEnd.listen((event) {
        if (request.status == 200) {
          print('Audio sent successfully');
          String serverResponse = request.responseText!;
          var jsonResponse = convert.jsonDecode(serverResponse);
          String result = jsonResponse['answer']; // Extract the "answer" field
          updateResult(result);
        } else {
          print('Failed to send audio: ${request.statusText}');
        }
      });
    } catch (e) {
      print('Failed to send audio: $e'); //TODO: Remove this line after debugging
    }
  }

  void sendCorrectedTextToServer(String correctedText) {
    try {
      var formData = html.FormData();
      formData.append('correctedText', correctedText);

      var request = html.HttpRequest();
      request.open('POST', 'http://localhost:5000/correctedText');
      request.send(formData);

      request.onLoadEnd.listen((event) {
        if (request.status == 200) {
          print('Corrected text sent successfully');
        } else {
          print('Failed to send corrected text: ${request.statusText}');
        }
      });
    } catch (e) {
      print('Failed to send corrected text: $e');
    }
  }
}