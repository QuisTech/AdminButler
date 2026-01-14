import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to database...');
  try {
    final connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 8090,
        database: 'admin_butler',
        username: 'postgres',
        password: 'mysecretpassword',
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
    print('Connected successfully!');
    await connection.close();
  } catch (e) {
    print('Connection failed: $e');
  }
}
