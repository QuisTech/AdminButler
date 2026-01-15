import 'dart:io';

void main() async {
  print('❌ ERROR: This script is deprecated!');
  print('Use environment variables instead:');
  print('  export DB_PASSWORD="your_password"');
  print('  export REDIS_PASSWORD="your_password"');
  print('  export GEMINI_API_KEY="your_key"');
  print('Then run: ./start_app.sh');
  exit(1);
}
