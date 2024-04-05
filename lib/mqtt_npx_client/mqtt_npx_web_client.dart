import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'mqtt_npx_client.dart';

class MqttNpx0Client extends MqttNpxClient {
  @override
  MqttClient client(
    String server,
    String clientIdentifier, {
    int maxConnectionAttempts = 3,
  }) {
    return MqttBrowserClient(
      server,
      clientIdentifier,
      maxConnectionAttempts: maxConnectionAttempts,
    );
  }

  @override
  MqttClient clientWithPort(String server, String clientIdentifier, int port) {
    return MqttBrowserClient.withPort(server, clientIdentifier, port);
  }
}
