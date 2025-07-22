import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';


class GroqService {
  static final String? _apiKey = dotenv.env['GROQ_API_KEY'];
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Stream<String> streamMessage(
    List<Map<String, String>> messages, {
    String model = 'llama-3-3-70b-instruct',
  }) async* {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception("GROQ_API_KEY not set in .env file.");
    }

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    });

    request.body = jsonEncode({
      'model': model,
      'stream': true,
      'messages': messages,
    });

    final response = await request.send();

    if (response.statusCode != 200) {
      final error = await response.stream.bytesToString();
      throw Exception('Groq Streaming Error: ${response.statusCode} - $error');
    }

    final utf8Stream = response.stream.transform(utf8.decoder);

    await for (final chunk in utf8Stream) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data);
            final content = json['choices'][0]['delta']['content'];
            if (content != null) yield content.toString();
          } catch (_) {
            // Ignore parse errors on incomplete lines
          }
        }
      }
    }
  }
}
