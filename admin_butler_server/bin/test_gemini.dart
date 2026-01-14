import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  final passwords = loadYaml(File('config/passwords.yaml').readAsStringSync());
  final apiKey = passwords['development']['geminiApiKey'];
  
  if (apiKey == null) {
    print('API key not found');
    return;
  }

  final configs = [
    {'model': 'gemini-1.5-flash', 'version': 'v1'},
    {'model': 'gemini-1.5-flash-latest', 'version': 'v1'},
    {'model': 'gemini-1.5-pro', 'version': 'v1'},
    {'model': 'gemini-pro', 'version': 'v1'},
  ];

  for (final config in configs) {
    print('--- Testing ${config['model']} with version ${config['version']} ---');
    final model = GenerativeModel(
      model: config['model']!, 
      apiKey: apiKey,
      apiVersion: config['version'],
    );
    
    try {
      final response = await model.generateContent([Content.text('Hi')]);
      print('SUCCESS: ${config['model']}');
      print('Response: ${response.text}');
      break;
    } catch (e) {
      print('FAILED: ${config['model']}: $e');
    }
  }
}
