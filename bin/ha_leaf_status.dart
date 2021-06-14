import 'package:dartnissanconnectna/dartnissanconnectna.dart';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

main() async {
  NissanConnectSession session = new NissanConnectSession(debug: false);
  final client = MqttServerClient('', '');
  try {
    await client.connect();
  } on NoConnectionException catch (e) {
    // Raised by the client when connection fails.
    print('MQTT::client exception - $e');
    client.disconnect();
  } on SocketException catch (e) {
    // Raised by the socket layer
    print('MQTT::socket exception - $e');
    client.disconnect();
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('MQTT::Mosquitto client connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print(
        'MQTT::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
    exit(-1);
  }

  const statusTopic = 'leaf/status';
  final builder = MqttClientPayloadBuilder();
  client.subscribe(statusTopic, MqttQos.exactlyOnce);

  session
      .login(username: 'dzarn@amovita.net', password: r'')
      .then((vehicle) {

    vehicle.requestBatteryStatus().then((battery) {
      var jsonBattery = {
        'vin': vehicle.vin,
        'nickname': vehicle.nickname,
        'updated': battery.dateTime.toString(),
        'batterylevel': battery.batteryLevel,
        'range': battery.cruisingRangeAcOnMiles,
        'plugged_in': battery.isConnected,
        'charging': battery.isCharging,
        'charge_time_trickle': battery.timeToFullTrickle.toString(),
        'charge_time_l2': battery.timeToFullL2.toString(),
        'charge_time_6kw': battery.timeToFullL2_6kw.toString(),
        'twelfth_bar': battery.battery12thBar
      };
      print(jsonBattery);

      builder.clear();
      builder.addString(jsonEncode(jsonBattery));
      client.publishMessage(statusTopic, MqttQos.exactlyOnce, builder.payload!);

      exit(0);
    });
  });
}
