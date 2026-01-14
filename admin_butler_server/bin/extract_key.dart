import 'dart:io';

void main() async {
  final file = File('config/passwords.yaml');
  if (await file.exists()) {
    final lines = await file.readAsLines();
    for (var line in lines) {
      if (line.trim().startsWith('geminiApiKey:')) {
        var key = line.split(':')[1].trim();
        if (key.startsWith("'") && key.endsWith("'")) {
          key = key.substring(1, key.length - 1);
        }
        await File('key.txt').writeAsString(key);
        print('Wrote key to key.txt');
        return;
      }
    }
  }
}
