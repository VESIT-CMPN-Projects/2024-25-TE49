import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class Chatbot1Page extends StatefulWidget {
  @override
  _Chatbot1PageState createState() => _Chatbot1PageState();
}

class _Chatbot1PageState extends State<Chatbot1Page> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _isLoading = false;
  bool _isModelInitialized = false;
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    const apiKey = 'AIzaSyDB7BOI1LpM3FrhfFUWmWbWjsmijykEKhg';
    if (apiKey.isEmpty) {
      stderr.writeln('No GEMINI_API_KEY environment variable');
      return;
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
      systemInstruction: Content.system(
        'You are a travel chatbot for generating travel itinerary anywhere around the world. If asked something other than travel itinerary politely reply I am trained only to answer queries related to travel itinerary. Answer in a proper format.',
      ),
    );
    setState(() {
      _isModelInitialized = true;
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || !_isModelInitialized) return;
    final message = _controller.text;
    _controller.clear();
    setState(() {
      _isLoading = true;
      _messages.add("You: $message");
    });
    try {
      final content = Content.text(message);
      final response = await _model.startChat(history: []).sendMessage(content);
      setState(() {
        _messages.add("WanderBot: ${_formatResponse(response.text ?? '')}");
      });
    } catch (e) {
      setState(() {
        _messages.add("WanderBot: Error occurred: $e");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatResponse(String text) {
    // Remove '#' signs
    text = text.replaceAll('#', '');

    // Add bold formatting
    text = text.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*'), (match) => '&lt;b&gt;${match[1]}&lt;/b&gt;');

    // Add italic formatting
    text = text.replaceAllMapped(
        RegExp(r'\*(.*?)\*'), (match) => '&lt;i&gt;${match[1]}&lt;/i&gt;');

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        title: Text('Chat with WanderBot'),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: !_isModelInitialized
          ? Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : Container(
              color: Colors.black,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUserMessage = message.startsWith("You: ");
                        return Align(
                          alignment: isUserMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isUserMessage
                                  ? Colors.indigoAccent
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: _parseTextSpans(message),
                              ),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          CircularProgressIndicator(color: Colors.indigoAccent),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.black54,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.indigoAccent,
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  List<TextSpan> _parseTextSpans(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'&lt;(\w+)&gt;(.*?)&lt;/\1&gt;');
    int start = 0;
    for (Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      String tag = match.group(1)!;
      String content = match.group(2)!;
      if (tag == 'b') {
        spans.add(TextSpan(
            text: content, style: TextStyle(fontWeight: FontWeight.bold)));
      } else if (tag == 'i') {
        spans.add(TextSpan(
            text: content, style: TextStyle(fontStyle: FontStyle.italic)));
      }
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}
