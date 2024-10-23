import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:trackmyrun/services/config_service.dart';
import 'package:trackmyrun/services/log_service.dart';
import 'config_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _tracking = false;
  String? _name;
  String? _number;
  String? _configError;
  DateTime? _lastPushDateTime;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadLastPushTime();
    _loadLogs();

    // Listen to background service for data updates
    FlutterBackgroundService().on("update").listen((event) {
      if (event != null) {
        _loadLastPushTime();
        _loadLogs();
      }
    });
  }

  Future<void> _loadConfig() async {
    final config = await ConfigService.loadConfig();
    setState(() {
      _name = config['name'];
      _number = config['number'];
      _validateConfig();
    });
  }

  bool _validateConfig() {
    if (_name == null ||
        _name!.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_name!)) {
      setState(() {
        _configError = 'Invalid name configuration';
      });
      return false;
    }

    final number = int.tryParse(_number ?? '');
    if (number == null || number < 1 || number > 999) {
      setState(() {
        _configError = 'Invalid bib number configuration';
      });
      return false;
    }

    setState(() {
      _configError = null;
    });
    return true;
  }

  Future<void> _loadLastPushTime() async {
    DateTime? lastPushTime = await LogService.getLastPushTime();
    setState(() {
      _lastPushDateTime = lastPushTime;
    });
  }

  Future<void> _loadLogs() async {
    List<String> logs = await LogService.getLogs();
    setState(() {
      _logs = logs;
    });
  }

  void _toggleTracking(bool value) async {
    if (value) {
      if (_validateConfig()) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Show dialog to prompt user to enable location services
          _showLocationServicesDialog();
          setState(() {
            _tracking = false;
          });
          return;
        }

        // Check and request permissions
        LocationPermission permission;
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
          if (permission != LocationPermission.always &&
              permission != LocationPermission.whileInUse) {
            // Permissions are not granted
            // Handle accordingly
            setState(() {
              _tracking = false;
            });
            return;
          }
        }

        setState(() {
          _tracking = true;
        });

        // Start the background service
        FlutterBackgroundService().startService();
      } else {
        setState(() {
          _tracking = false;
        });
      }
    } else {
      setState(() {
        _tracking = false;
      });
      FlutterBackgroundService().invoke("stopService");
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content:
          const Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfigPage()),
              );
              await _loadConfig();

              if (_tracking) {
                // Restart the background service to use the new configuration
                FlutterBackgroundService().invoke("stopService");
                FlutterBackgroundService().startService();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_configError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Please provide your name and bib number by configuring the app. Click on the settings icon at the top right.',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Column(
                  children: [
                    const Text(
                      'App configured. You can start tracking!',
                      style: TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    Text('Name: $_name'),
                    Text('Bib Number: $_number'),
                    const SizedBox(height: 20),
                  ],
                ),
              SwitchListTile(
                title: const Text('Tracking ON/OFF'),
                value: _tracking,
                onChanged: (bool value) {
                  _toggleTracking(value);
                },
                activeColor: _configError == null ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 20),
              if (_lastPushDateTime != null)
                Text(
                  'Last HTTP push success: ${DateFormat.yMMMd().add_jm().format(_lastPushDateTime!)}',
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 20),
              if (_logs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logs:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Text(
                              _logs[index],
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
