import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;

void main() async {
  final passwords = loadYaml(File('config/passwords.yaml').readAsStringSync());
  final apiKey = passwords['development']['geminiApiKey'];
  
  if (apiKey == null) {
    print('API key not found');
    return;
  }

  final endpoints = ['v1', 'v1beta'];
  
  for (var version in endpoints) {
    print('\n--- Testing endpoint $version ---');
    final url = Uri.parse('https://generativelanguage.googleapis.com/$version/models?key=$apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        for (var model in models) {
          final name = model['name'] as String;
          if (name.contains('gemini')) {
            print('- $name');
          }
        }
      } else {
        print('Error with $version: ${response.statusCode}');
      }
    } catch (e) {
      print('Error with $version: $e');
    }
  }
}
