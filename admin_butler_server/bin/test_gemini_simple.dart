import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  final passwords = loadYaml(File('config/passwords.yaml').readAsStringSync());
  final apiKey = passwords['development']['geminiApiKey'];
  
  print('Testing Gemini with apiKey: ${apiKey?.substring(0, 5)}...');
  
  final model = GenerativeModel(
    model: 'gemini-1.5-flash', 
    apiKey: apiKey!,
  );
  
  try {
    final response = await model.generateContent([Content.text('Hi')]);
    print('Response: ${response.text}');
  } catch (e) {
    print('Error: $e');
  }
}
