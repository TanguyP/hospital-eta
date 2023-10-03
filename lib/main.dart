import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'config.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? _bbox_corner_1;
  LatLng? _bbox_corner_2;
  num _duration_in_seconds = 0;
  GeoJsonParser? _geo_json_parser;

  initState() {
    fetchItinerary();
  }

  fetchItinerary() async {
    final response = await http.get(Uri.parse(Config.getItineraryUrl));

    final jsonBody = jsonDecode(response.body);
    final feature = jsonBody['data']['features'][0];
    setState(() {
      _duration_in_seconds = feature['properties']['summary']['duration'];

      final bbox = feature['bbox'];
      _bbox_corner_1 = LatLng(bbox[1], bbox[0]);
      _bbox_corner_2 = LatLng(bbox[3], bbox[2]);

      _geo_json_parser = GeoJsonParser();
      _geo_json_parser!.parseGeoJsonAsString(jsonEncode(jsonBody['data']));
    });
  }

  List<Widget> buildMapChildren() {
    List<Widget> children = [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      )
    ];

    if (_geo_json_parser != null) {
      children.add(PolygonLayer(polygons: _geo_json_parser!.polygons));
      children.add(PolylineLayer(polylines: _geo_json_parser!.polylines));
      children.add(MarkerLayer(markers: _geo_json_parser!.markers));
    }

    return children;
  }

  buildDurationText()  {
    if (_duration_in_seconds < 60) {
      return "$_duration_in_seconds seconds";
    }

    final minutes = _duration_in_seconds ~/ 60;
    return "$minutes minutes";
  }

  @override
  Widget build(BuildContext context) {
    MapOptions options;
    if (_bbox_corner_1 != null && _bbox_corner_2 != null) {
      options = MapOptions(
          bounds: LatLngBounds(_bbox_corner_1!, _bbox_corner_2!),
      );
    }
    else {
      options = MapOptions(center: LatLng(50.609, 3.032), zoom: 9);
    }

    return FlutterMap(
      options: options,
      nonRotatedChildren: [
        DefaultTextStyle.merge(
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white,
          ),
          child: Align(
            alignment: Alignment.topCenter.add(const Alignment(0.0, 0.12)),
            child: Text("Arrivée dans " + buildDurationText()),
          ),
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),
      ],
      children: buildMapChildren(),
    );
  }
}
