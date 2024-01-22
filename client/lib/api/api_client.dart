import 'dart:html' as html;
import 'dart:convert' as convert;
import 'package:flutter/material.dart';

class ApiClient {
  final Function(String) updateResult;
  final BuildContext context;

  ApiClient(this.updateResult, this.context);

  // Show the scafold message
  void showSnackBar({required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void sendAudioToServer(html.Blob audioBlob) {
    try {
      var formData = html.FormData();
      formData.appendBlob('file', audioBlob);

      var request = html.HttpRequest();
      request.open('POST', 'http://localhost:5000/calculate');
      request.send(formData);

      request.onLoadEnd.listen((event) {
        if (request.status == 200) {
          showSnackBar(message: 'Audio sent successfully');
          String serverResponse = request.responseText!;
          var jsonResponse = convert.jsonDecode(serverResponse);
          String result = jsonResponse['answer']; // Extract the "answer" field
          updateResult(result);
          print('Server response: $result');//TODO: Remove this line after debugging
        } else {
        }showSnackBar(message: 'Failed to send audio: ${request.statusText}');
      });
    } catch (e) {
      showSnackBar(message: 'Error on voice: $e');
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
          showSnackBar(message: 'Corrected text sent successfully');
        } else {
          showSnackBar(message: 'Failed to send corrected text: ${request.statusText}');
        }
      });
    } catch (e) {
      showSnackBar(message: 'Error on corrected text: $e');
    }
  }
}