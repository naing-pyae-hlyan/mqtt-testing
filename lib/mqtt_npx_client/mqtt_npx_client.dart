import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_npx_native_client.dart'
    if (dart.library.html) 'mqtt_npx_web_client.dart' as npx_client;

abstract class MqttNpxClient {
  static MqttNpxClient? _instance;
  static MqttNpxClient get instance {
    return _instance ??= npx_client.MqttNpx0Client();
  }

  MqttClient client(
    final String server,
    final String clientIdentifier, {
    final int maxConnectionAttempts = 3,
  });

  MqttClient clientWithPort(
    final String server,
    final String clientIdentifier,
    final int port,
  );
}
