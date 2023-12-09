import 'dart:math' as math;

class ConvGridGps {
  static const double RE = 6371.00877; // 지구 반경(km)
  static const double GRID = 5.0; // 격자 간격(km)
  static const double SLAT1 = 30.0; // 투영 위도1(degree)
  static const double SLAT2 = 60.0; // 투영 위도2(degree)
  static const double OLON = 126.0; // 기준점 경도(degree)
  static const double OLAT = 38.0; // 기준점 위도(degree)
  static const double XO = 43; // 기준점 X좌표(GRID)
  static const double YO = 136; // 기1준점 Y좌표(GRID)

  static const double DEGRAD = math.pi / 180.0;
  static const double RADDEG = 180.0 / math.pi;

  static double get re => RE / GRID;
  static double get slat1 => SLAT1 * DEGRAD;
  static double get slat2 => SLAT2 * DEGRAD;
  static double get olon => OLON * DEGRAD;
  static double get olat => OLAT * DEGRAD;

  static double get snTmp =>
      math.tan(math.pi * 0.25 + slat2 * 0.5) /
          math.tan(math.pi * 0.25 + slat1 * 0.5);
  static double get sn =>
      math.log(math.cos(slat1) / math.cos(slat2)) / math.log(snTmp);

  static double get sfTmp => math.tan(math.pi * 0.25 + slat1 * 0.5);
  static double get sf => math.pow(sfTmp, sn) * math.cos(slat1) / sn;

  static double get roTmp => math.tan(math.pi * 0.25 + olat * 0.5);

  static double get ro => re * sf / math.pow(roTmp, sn);

  static gridToGPS(int v1, int v2) {
    var rs = {};
    double theta;

    rs['x'] = v1;
    rs['y'] = v2;
    int xn = (v1 - XO).toInt();
    int yn = (ro - v2 + YO).toInt();
    var ra = math.sqrt(xn * xn + yn * yn);
    if (sn < 0.0) ra = -ra;
    var alat = math.pow((re * sf / ra), (1.0 / sn));
    alat = 2.0 * math.atan(alat) - math.pi * 0.5;

    if (xn.abs() <= 0.0) {
      theta = 0.0;
    } else {
      if (yn.abs() <= 0.0) {
        theta = math.pi * 0.5;
        if (xn < 0.0) theta = -theta;
      } else
        theta = math.atan2(xn, yn);
    }
    var alon = theta / sn + olon;
    rs['lat'] = alat * RADDEG;
    rs['lng'] = alon * RADDEG;

    return rs;
  }

  static gpsToGRID(double v1, double v2) {
    var rs = {};
    double theta;

    rs['lat'] = v1;
    rs['lng'] = v2;
    var ra = math.tan(math.pi * 0.25 + (v1) * DEGRAD * 0.5);
    ra = re * sf / math.pow(ra, sn);
    theta = v2 * DEGRAD - olon;
    if (theta > math.pi) theta -= 2.0 * math.pi;
    if (theta < -math.pi) theta += 2.0 * math.pi;
    theta *= sn;
    rs['x'] = (ra * math.sin(theta) + XO + 0.5).floor();
    rs['y'] = (ro - ra * math.cos(theta) + YO + 0.5).floor();

    return rs;
  }
}