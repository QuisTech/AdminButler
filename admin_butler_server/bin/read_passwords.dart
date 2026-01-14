import 'dart:io';

void main() async {
  final file = File('config/passwords.yaml');
  if (await file.exists()) {
    final lines = await file.readAsLines();
    for (var line in lines) {
      print('[LINE] $line');
    }
  } else {
    print('File not found');
  }
}
