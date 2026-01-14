import 'dart:io';

void main() async {
  final content = '''
# Configuration for development server
development:
  database: 'mysecretpassword'
  serviceSecret: 'somerandomservicesecret12345'
  geminiApiKey: 'AIzaSyCn36VozffzGtttGrjj00qF8aDWcNr8FBaQ'
''';
  await File('config/passwords.yaml').writeAsString(content);
  print('Written passwords.yaml');
}
