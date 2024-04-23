// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:nptt/mqtt_npx_client/_exp.dart';

const MQTT_AUTH_USERNAME = "qrorder_server";
const MQTT_AUTH_PASSWORD = "123456";
const MQTT_HOST = "157.245.198.209"; // "ws://157.245.198.209";
const MQTT_PRINTER_NAME = "P80B-202005250001";
// MQTT_LAST_WILL_TOPIC
void main() {
  final client = MqttNpxClient.instance.client(MQTT_HOST, '')
    ..logging(on: true)
    ..setProtocolV311();
  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final MqttClient client;
  const MyApp({super.key, required this.client});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MQTT Testing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        client: client,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final MqttClient client;
  const MyHomePage({
    super.key,
    required this.client,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ValueNotifier<String> connectionNotifier = ValueNotifier("---");
  final ValueNotifier<int> progressNotifier = ValueNotifier(0);
  final ValueNotifier<String> errorMessageNotifier = ValueNotifier("");
  final ValueNotifier<List<MqttReceivedMessage<MqttMessage>>>
      receivedMessageNotifier = ValueNotifier([]);

  final messageTxtCtrl = TextEditingController();

  Future<void> connect() async {
    messageTxtCtrl.clear();
    if (widget.client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      return;
    }

    progressNotifier.value = 1;
    connectionNotifier.value = "Connecting...";
    String error = "";
    try {
      await widget.client.connect(MQTT_AUTH_USERNAME, MQTT_AUTH_PASSWORD);
    } on NoConnectionException catch (e) {
      error = "NCE :: $e";
      widget.client.disconnect();
    } on SocketException catch (e) {
      error = "SE :: $e";
      widget.client.disconnect();
    } catch (e) {
      error = "UE :: $e";
      widget.client.disconnect();
    }

    if (widget.client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      widget.client.subscribe(MQTT_PRINTER_NAME, MqttQos.exactlyOnce);
      connectionNotifier.value = "Connected to $MQTT_HOST";
      progressNotifier.value = 0;
    } else {
      connectionNotifier.value = "";
      progressNotifier.value = 1;
      errorMessageNotifier.value = error;
    }
  }

  void disconnect() {
    errorMessageNotifier.value = "";
    connectionNotifier.value = "---";
    if (widget.client.connectionStatus?.state !=
        MqttConnectionState.disconnected) {
      progressNotifier.value = 1;
      connectionNotifier.value = "Disconnecting...";
      widget.client.disconnect();
      progressNotifier.value = 0;
      connectionNotifier.value = "Disconnected";
    }
  }

  Future<void> sendMessage() async {
    errorMessageNotifier.value = "";
    FocusScope.of(context).requestFocus(FocusNode());
    final message = messageTxtCtrl.text;
    if (message.isEmpty) return;

    final payloadBuilder = MqttClientPayloadBuilder();
    payloadBuilder.addString(message);
    if (payloadBuilder.payload != null) {
      widget.client.publishMessage(
        MQTT_PRINTER_NAME,
        MqttQos.exactlyOnce,
        payloadBuilder.payload!,
      );
      messageTxtCtrl.clear();
    }
  }

  @override
  void initState() {
    super.initState();

    widget.client.published?.listen((MqttPublishMessage message) {
      if (message.variableHeader?.returnCode ==
          MqttConnectReturnCode.connectionAccepted) {
        messageTxtCtrl.clear;
      } else {
        errorMessageNotifier.value = "Failed to publish message";
      }
    });
  }

  @override
  void dispose() {
    if (mounted) {
      messageTxtCtrl.dispose();
      connectionNotifier.dispose();
      progressNotifier.dispose();
      errorMessageNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                'MQTT',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder(
                valueListenable: connectionNotifier,
                builder: (_, __, ___) => Text(
                  connectionNotifier.value,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder(
                valueListenable: progressNotifier,
                builder: (_, __, ___) {
                  if (widget.client.connectionStatus?.state ==
                      MqttConnectionState.connected) {
                    return _connectedWidget();
                  }

                  if (progressNotifier.value == 0) {
                    return emptyUi;
                  }

                  return const CircularProgressIndicator.adaptive();
                },
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder(
                valueListenable: errorMessageNotifier,
                builder: (_, __, ___) {
                  return Text(
                    errorMessageNotifier.value,
                    style: const TextStyle(color: Colors.red),
                  );
                },
              ),
            ],
          ),
        ),
        persistentFooterButtons: [
          TextButton.icon(
            onPressed: connect,
            icon: const Icon(Icons.wifi),
            label: const Text("Connect"),
          ),
          TextButton.icon(
            onPressed: disconnect,
            icon: const Icon(Icons.wifi_off, color: Colors.red),
            label: const Text(
              "Disconnect",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectedWidget() => Expanded(
        child: Column(
          children: [
            TextField(
              controller: messageTxtCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: "Enter your message",
                filled: true,
                contentPadding: EdgeInsets.all(8),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSubmitted: (String message) {
                sendMessage();
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: sendMessage,
                icon: const Icon(Icons.send_outlined),
                label: const Text("Send Message"),
              ),
            ),
            const SizedBox(height: 8),
            _updatedMessages,
          ],
        ),
      );

  Widget get _updatedMessages => StreamBuilder(
        stream: widget.client.updates,
        builder: (_, snapshot) {
          if (snapshot.data is List<MqttReceivedMessage<MqttMessage>>) {
            final messages =
                snapshot.data as List<MqttReceivedMessage<MqttMessage>>;

            return Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, index) {
                  final publishMessage =
                      messages[index].payload as MqttPublishMessage;
                  final msg = MqttPublishPayload.bytesToStringAsString(
                    publishMessage.payload.message,
                  );
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(
                      messages[index].topic,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      msg,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemCount: messages.length,
              ),
            );
          }
          return emptyUi;
        },
      );
}

const emptyUi = SizedBox.shrink();
