// 📁 ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'groq_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String _selectedModel = 'llama-3.3-70b-versatile';
  bool _isLoading = false;

  final List<String> _groqModels = [
    'llama-3.3-70b-versatile',
    'llama3-70b-8192',
    'llama3-8b-8192',
    'llama-3.1-8b-instant',
    'gemma2-9b-it',
    'deepseek-r1-distill-llama-70b',
    'meta-llama/llama-4-maverick-17b-128e-instruct',
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'meta-llama/llama-guard-4-12b',
    'meta-llama/llama-prompt-guard-2-22m',
    'meta-llama/llama-prompt-guard-2-86m',
    'mistral-saba-24b',
    'compound-beta',
    'compound-beta-mini',
    'moonshotai/kimi-k2-instruct',
    'qwen/qwen3-32b',
  ];

 Future<void> _sendMessage() async {
  final input = _controller.text.trim();
  if (input.isEmpty || _isLoading) return;

  setState(() {
    _messages.add({'role': 'user', 'content': input});
    _controller.clear();
    _isLoading = true;
    _messages.add({'role': 'assistant', 'content': ''}); // Placeholder for stream
  });

  final buffer = StringBuffer();

  final stream = GroqService.streamMessage(
    _messages.sublist(0, _messages.length - 1), // exclude placeholder
    model: _selectedModel,
  );

  stream.listen(
    (chunk) {
      buffer.write(chunk);
      setState(() {
        _messages[_messages.length - 1] = {
          'role': 'assistant',
          'content': buffer.toString(),
        };
      });
    },
    onDone: () {
      setState(() => _isLoading = false);
    },
    onError: (error) {
      setState(() {
        _isLoading = false;
        _messages[_messages.length - 1] = {
          'role': 'assistant',
          'content': '❌ Error: $error',
        };
      });
    },
    cancelOnError: true,
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groq Chatbot'),
        actions: [
          DropdownButtonHideUnderline(
  child: DropdownButton<String>(
    dropdownColor: Colors.blueGrey[900],
    iconEnabledColor: Colors.white,
    value: _selectedModel,
    onChanged: (value) {
      setState(() {
        _selectedModel = value!;
      });
    },
    selectedItemBuilder: (BuildContext context) {
      return _groqModels.map<Widget>((String model) {
        return Row(
          children: [
            Text(
              model,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        );
      }).toList();
    },
    items: _groqModels.map((model) {
      return DropdownMenuItem(
        value: model,
        child: Text(
          model,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }).toList(),
  ),
),

          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
