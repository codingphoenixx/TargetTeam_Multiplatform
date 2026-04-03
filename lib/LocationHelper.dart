import 'dart:math' as math;

import 'package:TargetTeam/MathUtils.dart';
import 'package:proj4dart/proj4dart.dart';

class LocationHelper {
  static const double A = 6378137.0;
  static const double F = 0.0033528106647474805;
  static const double K0 = 0.9996;
  static Projection? wgs84Projection = Projection.get("EPSG:4326");
  static Projection? etrs89Projection = Projection.add("EPSG:25832","+proj=utm +zone=32 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs");

  static List<String> convertLatLonToUTMWGS84(
      double latitude, double longitude) {
    final latRad = _toRadians(latitude);
    final lonRad = _toRadians(longitude);
    final zone = (MathUtils.floor((longitude + 180.0) / 6.0) + 1).toInt();
    final lonOrigin =
    _toRadians(((zone - 1) * 6 - 180) + 3);
    final e = math.sqrt(0.0066943799901413165);
    final N = A / math.sqrt(1.0 - math.pow(math.sin(latRad) * e, 2.0));
    final T = math.pow(math.tan(latRad), 2.0);
    final C = math.pow(e * math.cos(latRad), 2.0);
    final lonRad2 = math.cos(latRad) * (lonRad - lonOrigin);

    final M = (
        (1.0 - (math.pow(e, 2.0) / 4.0) - (3.0 * math.pow(e, 4.0) / 64.0) - (5.0 * math.pow(e, 6.0) / 256.0)) * latRad
            - ((3.0 * math.pow(e, 2.0) / 8.0) + (3.0 * math.pow(e, 4.0) / 32.0) + (45.0 * math.pow(e, 6.0) / 1024.0)) * math.sin(2.0 * latRad)
            + ((15.0 * math.pow(e, 4.0) / 256.0) + (45.0 * math.pow(e, 6.0) / 1024.0)) * math.sin(4.0 * latRad)
            - (35.0 * math.pow(e, 6.0) / 3072.0) * math.sin(6.0 * latRad)
    ) * A;

    final easting = (N * K0 * (
        lonRad2
            + ((1.0 - T + C) * math.pow(lonRad2, 3.0) / 6.0)
            + (((5.0 - 18.0 * T + T * T + 72.0 * C - 58.0 * e * e) * math.pow(lonRad2, 5.0)) / 120.0)
    )) + 500000.0;

    var northing = (
        M + N * math.tan(latRad) * (
            (lonRad2 * lonRad2 / 2.0)
                + (((5.0 - T + 9.0 * C + 4.0 * C * C) * math.pow(lonRad2, 4.0)) / 24.0)
                + (((61.0 - 58.0 * T + T * T + 600.0 * C - 330.0 * e * e) * math.pow(lonRad2, 6.0)) / 720.0)
        )
    ) * K0;

    if (latitude < 0.0) {
      northing += 1.0E7;
    }

    final roundEasting = easting.round();
    final roundNorthing = northing.round();

    return [
      '$zone ${getUTMZoneLetter(latitude)}',
      roundEasting.toString(),
      roundNorthing.toString(),
    ];
  }

  static String getUTMZoneLetter(double latitude) {
    const letters = [
      'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
      'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X'
    ];
    final index = (MathUtils.floor((latitude + 80.0) / 8.0)).toInt();
    return letters[index];
  }

  static double convertMetersPerSecondToKilometersPerHour(
      double metersPerSecond) {
    return 3.6 * metersPerSecond;
  }

  static List<String> convertLatLonToUTMETRS89(
      double latitude, double longitude) {
    final zone = (MathUtils.floor((longitude + 180.0) / 6.0) + 1).toInt();


    final pointSrc = Point(x: longitude, y: latitude);
    final pointDst = wgs84Projection?.transform(etrs89Projection!, pointSrc);

    final easting = (pointDst!.x * 100).round() / 100.0;
    final northing = (pointDst.y * 100).round() / 100.0;

    return [
      '$zone ${getUTMZoneLetter(latitude)}',
      easting.toStringAsFixed(0),
      northing.toStringAsFixed(0),
    ];
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}