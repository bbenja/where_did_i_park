import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'monospace',
            ),
      ),
      home: const LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  double? lat;
  double? lon;
  String? timestamp;
  double? accuracy;

  @override
  void initState() {
    super.initState();
    loadLastLocation();
  }

  Future<void> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lat = prefs.getDouble('lat');
      lon = prefs.getDouble('lon');
      accuracy = prefs.getDouble('accuracy');
      timestamp = prefs.getString('timestamp');
    });
  }

  Future<void> getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final now = DateTime.now();
    final t = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} "
        "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', pos.latitude);
    await prefs.setDouble('lon', pos.longitude);
    await prefs.setDouble('accuracy', pos.accuracy);
    await prefs.setString('timestamp', t);

    setState(() {
      lat = pos.latitude;
      lon = pos.longitude;
      accuracy = pos.accuracy;
      timestamp = t;
    });
  }

  void copyToClipboard() {
    if (lat == null || lon == null) return;
    Clipboard.setData(ClipboardData(text: "$lat,$lon"));
  }

  Future<void> openInGoogleMaps() async {
    if (lat == null || lon == null) return;
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Where did I park?")),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    lat != null && lon != null
                        ? "$lat\n$lon"
                        : "--\n--",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timestamp != null
                        ? "$timestamp\n± ${accuracy?.toStringAsFixed(0)} m"
                        : "--",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: getLocation,
                  child: const Text("REFRESH"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: copyToClipboard,
                  child: const Text("COPY"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: openInGoogleMaps,
                  child: const Text("MAPS"),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

}
