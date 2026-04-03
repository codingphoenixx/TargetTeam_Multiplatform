import 'dart:async';

import 'package:TargetTeam/LocationHelper.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationMode { latLong, wgs84, etrs89 }

class PositionProvider extends ChangeNotifier {
  static PositionProvider? _instance;

  static PositionProvider get instance => _instance ??= PositionProvider._internal();

  PositionProvider._internal() {
    _init();
  }

  Position? _position;
  LocationMode _locationMode = LocationMode.latLong;
  double _heightCorrection = 48.7590;
  static const double feetToMeterConstant = 3.278688525;
  static const int staleSeconds = 15;
  Timer? _timer;

  Position? get position => _position;

  LocationMode get locationMode => _locationMode;

  double get heightCorrection => _heightCorrection;

  Future<void> _init() async {
    await _loadPreferences();
    _startLocationUpdates();

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
        timeLimit: null,
        intervalDuration: const Duration(seconds: 0),
        useMSLAltitude: true,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: null,
        activityType: ActivityType.airborne,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: null,
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

  bool isStale() {
    final now = DateTime.now();
    bool redColor = false;
    if (position != null && position!.timestamp != null) {
      redColor = now.difference(position!.timestamp).inSeconds > staleSeconds;
    }
    return redColor;
  }

  String getFormattedAltitude() {
    if (_position == null) return '';

    final meters = (_position!.altitude - _heightCorrection).toStringAsFixed(0);
    final feet =
        ((_position!.altitude - _heightCorrection) * feetToMeterConstant)
            .toStringAsFixed(0);
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
