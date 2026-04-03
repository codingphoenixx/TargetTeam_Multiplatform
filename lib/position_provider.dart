import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:targetteam_multiplatform/LocationHelper.dart';
import 'package:targetteam_multiplatform/TargetTeamApp.dart';

enum LocationMode { latLong, wgs84, etrs89 }

class PositionProvider extends ChangeNotifier {
  static PositionProvider? _instance;

  static PositionProvider get instance =>
      _instance ??= PositionProvider._internal();

  PositionProvider._internal() {
    _init();
  }

  Position? _position;
  LocationMode _locationMode = LocationMode.latLong;
  double _heightCorrection = 48.7590;
  Timer? _timer;

  Position? get position => _position;

  LocationMode get locationMode => _locationMode;

  double get heightCorrection => _heightCorrection;

  Future<void> _init() async {
    await _loadPreferences();
    _startLocationUpdates();
    _timer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => notifyListeners(),
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _heightCorrection = prefs.getDouble('heightCorrection') ?? 48.7590;
    final modeString = prefs.getString('locationMode') ?? 'latLong';
    _locationMode = LocationMode.values.firstWhere(
      (e) => e.toString().split('.').last == modeString,
      orElse: () => LocationMode.latLong,
    );
  }

  Future<void> setHeightCorrection(double value) async {
    _heightCorrection = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('heightCorrection', value);
    notifyListeners();
  }

  Future<void> setLocationMode(LocationMode mode) async {
    _locationMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locationMode', mode.toString().split('.').last);
    notifyListeners();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    var locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 0),
        useMSLAltitude: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.airborne,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position pos,
    ) {
      _position = pos;
      notifyListeners();
    });
  }

  String getFormattedPosition() {
    if (_position == null) return '';
    switch (_locationMode) {
      case LocationMode.etrs89:
        final strings = LocationHelper.convertLatLonToUTMETRS89(
          _position!.latitude,
          _position!.longitude,
        );
        return '${strings[0]} ${strings[1]}\n${strings[2]}';
      case LocationMode.wgs84:
        final strings = LocationHelper.convertLatLonToUTMWGS84(
          _position!.latitude,
          _position!.longitude,
        );
        return '${strings[0]} ${strings[1]}\n${strings[2]}';
      case LocationMode.latLong:
      default:
        return '${_position!.latitude.toStringAsFixed(6)}\n'
            '${_position!.longitude.toStringAsFixed(6)}';
    }
  }

  String getFormattedAltitude() {
    if (_position == null) return '';

    final meters = (_position!.altitude - _heightCorrection).round();
    final feet = ((_position!.altitude - _heightCorrection) * 3.278688525)
        .round();
    return '$meters m / $feet ft';
  }

  String getFormattedAccuracy() {
    if (_position == null) return '';
    return '${_position!.accuracy.round()} m (${_position!.altitudeAccuracy.round()} m)';
  }

  String getFormattedTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  Future<void> showChangeHeightDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _heightCorrection.toString(),
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Höhenkorrekturfaktor ändern (in m)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Höhenkorrekturfaktor'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                setHeightCorrection(value);
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void sharePosition(BuildContext context, {String? comment}) {
    if (_position == null) return;
    final body = [
      if (comment != null && comment.isNotEmpty) '$comment:\n',
      _locationMode.toString().split('.').last.toUpperCase(),
      getFormattedPosition(),
      'Höhe: ${getFormattedAltitude()}',
      'Genauigkeit: ${getFormattedAccuracy()}',
      'HC: $_heightCorrection',
      'LT: ${_position!.timestamp.millisecondsSinceEpoch ?? ''}',
      'CT: ${DateTime.now().millisecondsSinceEpoch}',
      'V: ${TargetTeamApp.version}:${TargetTeamApp.buildVersion}',
    ].join('\n');

    SharePlus.instance.share(ShareParams(subject: "Position", text: body));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
