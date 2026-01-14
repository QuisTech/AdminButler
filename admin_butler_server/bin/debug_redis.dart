import 'dart:io';

void main() async {
  print('Connecting to Redis...');
  try {
    final socket = await Socket.connect('localhost', 8091);
    print('Connected to Redis successfully!');
    await socket.close();
  } catch (e) {
    print('Redis connection failed: $e');
  }
}
