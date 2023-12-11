import 'dart:convert';
import 'package:flutter/material.dart';
import './convGridGps.dart';
import 'package:location/location.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String formattedDate = '';
  String weatherData = '';
  String temperature = ''; // 25℃
  String skyStatus = ''; // 맑음
  String ptyStatus = ''; // 비, 눈 어쩌구
  String humidity = ''; // 습도\n60%
  String wind = ''; // 바람\nN 5 m/s
  String precipitationStatus = ''; // 강수 상태\n-
  String lgtStatus = '';
  String status = '';
  Color bgColor = Colors.white;
  Color bgColorTemp = Colors.white;
  Color ftColor = Colors.black;
  String monthDay = '';
  String image = 'assets/icons/snowRain.png';

  List<Map<String, String>> hourlyWeather = [];

  @override
  void initState() {
    super.initState();
    // 앱이 시작될 때 날씨 정보 가져옴
    getWeatherData();
  }

  void updateWeatherInfo(int index) {
    if (mounted) {
      setState(() {
        formattedDate = '${hourlyWeather[index]['time']}';
        temperature = '${hourlyWeather[index]['temperature']}';
        skyStatus = '${hourlyWeather[index]['skyStatus']}';
        ptyStatus = '${hourlyWeather[index]['ptyStatus']}';
        humidity = '${hourlyWeather[index]['humidity']}';
        wind = '${hourlyWeather[index]['wind']}';
        precipitationStatus = '${hourlyWeather[index]['rainfall']}';
        lgtStatus = '${hourlyWeather[index]['lgtStatus']}';

        if (skyStatus == '맑음' && precipitationStatus == '강수랑\n-') {
          bgColorTemp = Colors.lightBlue;
          bgColor = Colors.lightBlueAccent;
          ftColor = Colors.white;
          status = skyStatus;
        } else if (precipitationStatus == '강수랑\n-') {
          bgColorTemp = Colors.blueGrey.shade600;
          bgColor = Colors.blueGrey;
          ftColor = Colors.white;
          status = skyStatus;
        } else {
          bgColorTemp = Colors.grey;
          bgColor = Colors.blueGrey;
          ftColor = Colors.white;
          status = ptyStatus;
        }

        if (lgtStatus == '0kA') {
          if (precipitationStatus == '강수랑\n-') {
            image = _getWeatherImage(skyStatus);
          } else {
            image = _getPrecipitationImage(ptyStatus);
          }
        } else {
          status = lgtStatus;
          if (precipitationStatus == '강수랑\n-') {
            image = _getWeatherThunderImage(skyStatus);
          } else {
            image = _getPrecipitationThunderImage(ptyStatus);
          }
        }
      });
    }
  }


  // 현재 (위치/시간) 받아오고, 시간 단위로 다음 예보 뽑아오기
  Future<void> getWeatherData() async {
    try {
      DateTime scheduledTime = DateTime.now();
      DateTime updatedTime = scheduledTime.add(Duration(hours: 8));
      monthDay = '${updatedTime.month}월 ${updatedTime.day}일';
      print(updatedTime);
      print(monthDay);

      Location location = new Location();
      LocationData _locationData = await location.getLocation();

      var lat = _locationData.latitude;
      var long = _locationData.longitude;

      var day = '0';
      if ('${updatedTime.day}'.length == 1) {
        day = '$day${updatedTime.day - 1}';
      } else {
        day = '${updatedTime.day}';
      }
      var hour = '0';
      if ('${updatedTime.hour}'.length == 1) {
        hour = '$hour${updatedTime.hour}';
      } else {
        hour = '${updatedTime.hour}';
      }
      var min = '0';
      if ('${updatedTime.minute}'.length == 1) {
        min = '$min${updatedTime.minute}';
      } else {
        min = '${updatedTime.minute}';
      }

      var gpsToGridData = ConvGridGps.gpsToGRID(lat!, long!);
      print(updatedTime);
      print(gpsToGridData);

      var baseDate = '${updatedTime.year}${updatedTime.month}$day';
      var baseTime = '$hour$min';
      print('$baseDate$baseTime');
      final url = Uri.parse(
          "http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtFcst");
      final params = {
        'serviceKey':
        '4uIiQhsuu0bQtrHxzleNU7xH03OmYqOniRoZfNlzyZuuppsvQecRiGnTmJ47qdA3270X+kKD3fg4L6W/GUNKkw==',
        'numOfRows': '1000',
        'pageNo': '1',
        'dataType': 'JSON',
        'base_date': baseDate,
        'base_time': baseTime,
        'nx': '${gpsToGridData['x']}',
        'ny': '${gpsToGridData['y']}'
      };
      print(params);

      final response = await http.get(url.replace(queryParameters: params));
      if (response.statusCode == 200) {
        // API 응답이 성공
        final jsonString = response.body;
        print(jsonString);
        var processedData = processWeatherData(jsonString);
        if (mounted) {
          setState(() {
            weatherData = processedData;
            formattedDate = '${hourlyWeather[0]['time']}';
            temperature = '${hourlyWeather[0]['temperature']}';
            skyStatus = '${hourlyWeather[0]['skyStatus']}';
            ptyStatus = '${hourlyWeather[0]['ptyStatus']}';
            humidity = '${hourlyWeather[0]['humidity']}';
            wind = '${hourlyWeather[0]['wind']}';
            precipitationStatus = '${hourlyWeather[0]['rainfall']}';
            lgtStatus = '${hourlyWeather[0]['lgtStatus']}';

            if (skyStatus == '맑음') {
              bgColorTemp = Colors.lightBlue;
              bgColor = Colors.lightBlueAccent;
              ftColor = Colors.white;
              status = skyStatus;
            } else if (precipitationStatus == '강수랑\n-') {
              bgColorTemp = Colors.blueGrey.shade600;
              bgColor = Colors.blueGrey;
              ftColor = Colors.white;
              status = skyStatus;
            } else {
              bgColorTemp = Colors.blueGrey.shade600;
              bgColor = Colors.blueGrey;
              ftColor = Colors.white;
              status = ptyStatus;
            }

            if (lgtStatus == '0kA') {
              if (precipitationStatus == '강수랑\n-') {
                image = _getWeatherImage(skyStatus);
              } else {
                image = _getPrecipitationImage(ptyStatus);
              }
            } else {
              status = lgtStatus;
              if (precipitationStatus == '강수랑\n-') {
                image = _getWeatherThunderImage(skyStatus);
              } else {
                image = _getPrecipitationThunderImage(ptyStatus);
              }
            }
          });
        }
      } else {
        // API 응답이 실패
        if (mounted) {
          setState(() {
            weatherData = 'Failed to load weather data: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      // 오류 발생 시 처리
      if (mounted) {
        setState(() {
          weatherData = 'Error: $e';
        });
      }
    }
  }


  String processWeatherData(String jsonString) {
    Map<String, Map<String, String>> informations = {};

    var jsonData = json.decode(jsonString);
    var items = jsonData['response']['body']['items']['item'];

    for (var item in items) {
      var cate = item['category'];
      var fcstTime = item['fcstTime'].toString();
      var fcstValue = item['fcstValue'].toString();

      if (!informations.containsKey(fcstTime)) {
        informations[fcstTime] = {};
      }

      informations[fcstTime]![cate] = fcstValue;
    }

    var result = '';
    var skyTemp, ptyTemp, rn1Temp, t1hTemp, rehTemp, vecTemp, wsdTemp, lgtTemp;
    for (var key in informations.keys) {
      var val = informations[key]!;
      var template = "$key: ";

      if (val['SKY'] != null) {
        skyTemp = skyCode[int.parse(val['SKY']!)]!;
        template += "$skyTemp ,";
      }

      if (val['PTY'] != null) {
        ptyTemp = ptyCode[int.parse(val['PTY']!)]!;
        template += '$ptyTemp ,';
      }

      if (val['RN1'] != '강수없음') {
        rn1Temp = "강수량\n${val['RN1']!}";
        template += rn1Temp;
      } else {
        rn1Temp = '강수랑\n-';
      }

      if (val['T1H'] != null) {
        t1hTemp = double.parse(val['T1H']!);
        template += " 기온 $t1hTemp℃ ,";
      }

      if (val['REH'] != null) {
        rehTemp = double.parse(val['REH']!);
        template += "습도\n$rehTemp% ,";
      }

      if (val['VEC'] != null && val['WSD'] != null) {
        vecTemp = degToDir(double.parse(val['VEC']!));
        wsdTemp = val['WSD']!;
        template += "풍속 $wsdTemp m/s, 방향 $vecTemp ,";
      }
      if (val['LGT'] != null) {
        if (val['LGT'] != '0') {
          // lgtTemp = double.parse(val['LGT']!);
          lgtTemp = '낙뢰 주의';
          template += "낙뢰 ${double.parse(val['LGT']!)}kA ,";
        } else {
          lgtTemp = '0kA';
        }
      }

      result += template;
      result += "\n";
      hourlyWeather.add({
        'time': '$monthDay ${key.substring(0, 2)}시',
        'temperature': '$t1hTemp℃',
        'skyStatus': '$skyTemp',
        'ptyStatus': '$ptyTemp',
        'rainfall': '$rn1Temp',
        'humidity': '습도\n$rehTemp%',
        'wind': '바람\n$vecTemp ${wsdTemp}m/s',
        'lgtStatus': lgtTemp
      });
    }

    return result;
  }

  String _getWeatherImage(String skyStatus) {
    print(skyStatus);
    switch (skyStatus) {
      case '맑음':
        return 'assets/icons/sunny.png';
      case '구름 많음':
        return 'assets/icons/cloudy.png';
      case '흐림':
        return 'assets/icons/day_cloudy.png';
      default:
        return 'assets/icons/snowRain.png';
    }
  }

  String _getWeatherThunderImage(String skyStatus) {
    print(skyStatus);
    switch (skyStatus) {
      case '맑음':
        return 'assets/icons/lighting.png';
      case '구름 많음':
        return 'assets/icons/cloudy_thunder.png';
      case '흐림':
        return 'assets/icons/cloud_thunder.png';
      default:
        return 'assets/icons/snowRain.png';
    }
  }

  IconData _getWeatherIcon(String skyStatus) {
    switch (skyStatus) {
      case '맑음':
        return WeatherIcons.day_sunny;
      case '구름 많음':
        return WeatherIcons.day_cloudy;
      case '흐림':
        return WeatherIcons.cloudy;
      default:
        return WeatherIcons.lunar_eclipse;
    }
  }

  IconData _getWeatherThunderIcon(String skyStatus) {
    switch (skyStatus) {
      case '맑음':
        return WeatherIcons.lightning;
      case '구름 많음':
        return WeatherIcons.day_lightning;
      case '흐림':
        return WeatherIcons.thunderstorm;
      default:
        return WeatherIcons.lunar_eclipse;
    }
  }

  _getPrecipitationImage(String ptyStatus) {
    switch (ptyStatus) {
      case '비':
        return 'rainy.png';
      case '비/눈':
        return 'assets/icons/sleet.png';
      case '눈':
        return 'assets/icons/snow.png';
      case '빗방울':
        return 'assets/icons/wind_rain.png';
      case '빗방울 눈날림':
        return 'assets/icons/sleet.png';
      case '눈날림':
        return 'assets/icons/wind_snow.png';
      default:
        return 'assets/icons/snowRain.png';
    }
  }

  _getPrecipitationThunderImage(String ptyStatus) {
    switch (ptyStatus) {
      case '비':
        return 'assets/icons/rainy_thunder.png';
      case '비/눈':
        return 'assets/icons/sleet_thunder.png';
      case '눈':
        return 'assets/icons/snow_thunder.png';
      case '빗방울':
        return 'assets/icons/rain_thunder.png';
      case '빗방울 눈날림':
        return 'assets/icons/sleet_thunder.png';
      case '눈날림':
        return 'assets/icons/snow_thunder.png';
      default:
        return 'assets/icons/snowRain.png';
    }
  }

  IconData _getPrecipitationIcon(String ptyStatus) {
    switch (ptyStatus) {
      case '비':
        return WeatherIcons.rain;
      case '비/눈':
        return WeatherIcons.sleet;
      case '눈':
        return WeatherIcons.snow;
      case '빗방울':
        return WeatherIcons.rain_wind;
      case '빗방울 눈날림':
        return WeatherIcons.sleet;
      case '눈날림':
        return WeatherIcons.snow_wind;
      default:
        return WeatherIcons.lunar_eclipse;
    }
  }

  IconData _getPrecipitationThunderIcon(String ptyTemp) {
    switch (ptyTemp) {
      case '비':
        return WeatherIcons.thunderstorm;
      case '비/눈':
        return WeatherIcons.night_sleet_storm;
      case '눈':
        return WeatherIcons.night_snow_thunderstorm;
      case '빗방울':
        return WeatherIcons.rain_wind;
      case '빗방울 눈날림':
        return WeatherIcons.night_sleet_storm;
      case '눈날림':
        return WeatherIcons.night_snow_thunderstorm;
      default:
        return WeatherIcons.lunar_eclipse;
    }
  }

  // 하늘 상태 코드
  Map<int, String> skyCode = {1: '맑음', 3: '구름 많음', 4: '흐림'};

  // 강수 상태 코드
  Map<int, String> ptyCode = {
    0: '강수 없음',
    1: '비',
    2: '비/눈',
    3: '눈',
    5: '빗방울',
    6: '빗방울 눈날림',
    7: '눈날림'
  };

  // 풍향 코드
  String degToDir(double deg) {
    Map<double, String> degCode = {
      0: 'N',
      360: 'N',
      180: 'S',
      270: 'W',
      90: 'E',
      22.5: 'NNE',
      45: 'NE',
      67.5: 'ENE',
      112.5: 'ESE',
      135: 'SE',
      157.5: 'SSE',
      202.5: 'SSW',
      225: 'SW',
      247.5: 'WSW',
      292.5: 'WNW',
      315: 'NW',
      337.5: 'NNW'
    };

    String closeDir = '';
    double minAbs = 360;

    if (!degCode.containsKey(deg)) {
      degCode.forEach((key, value) {
        if ((key - deg).abs() < minAbs) {
          minAbs = (key - deg).abs();
          closeDir = value;
        }
      });
    } else {
      closeDir = degCode[deg]!;
    }

    return closeDir;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUpperHalf(),
            SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(top: 8),
              // Adjust the top margin as needed
              child: _buildLowerHalf(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpperHalf() {
    return Column(
      children: [
        Text(
          formattedDate,
          style: TextStyle(fontSize: 24, color: ftColor, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          temperature,
          style: TextStyle(fontSize: 30, color: ftColor, fontWeight: FontWeight.bold),
        ),
        Image.asset(
          image,
          height: 100, // Adjust the height as needed
          width: 100, // Adjust the width as needed
        ),
        SizedBox(height: 20),
        Text(
          status,
          style: TextStyle(fontSize: 30, color: ftColor, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            _buildInfoCard(humidity),
            _buildInfoCard(wind),
            _buildInfoCard(precipitationStatus),
          ],
        ),
        SizedBox(height: 20),
        _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return weatherData.isEmpty
        ? Column(
      children: [
        CircularProgressIndicator(color: Colors.black),
        SizedBox(height: 10), // 인디케이터와 텍스트 사이 간격
        Text("날씨 데이터를 불러오는 중입니다..", style: TextStyle(color: ftColor)),
      ],
    )
        : SizedBox(); // 날씨 데이터가 있을 경우 로딩 인디케이터를 숨깁니다.
  }

  Widget _buildLowerHalf() {
    return _buildHourlyForecast();
  }

  Widget _buildInfoCard(String info) {
    return Expanded(
      child: Card(
        elevation: 5,
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            info,
            style: TextStyle(fontSize: 16, color: ftColor),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: hourlyWeather.asMap().entries.map(
              (entry) {
            var icon;
            if (entry.value['lgtStatus'] == '0kA') {
              if (entry.value['rainfall'] == '강수랑\n-') {
                icon = _getWeatherIcon(entry.value['skyStatus']!);
              } else {
                icon = _getPrecipitationIcon(entry.value['ptyStatus']!);
              }
            } else {
              if (entry.value['rainfall'] == '강수랑\n-') {
                icon = _getWeatherThunderIcon(entry.value['skyStatus']!);
              } else {
                icon = _getPrecipitationThunderIcon(entry.value['ptyStatus']!);
              }
            }

            return Row(
              children: [
                ElevatedButton(
                  onPressed: () => updateWeatherInfo(entry.key),
                  style: ElevatedButton.styleFrom(
                    primary: bgColorTemp, // Customize the button color
                  ).merge(
                    ButtonStyle(
                      minimumSize:
                      MaterialStateProperty.all(Size(100, 100)), // 고정 크기
                      // 다른 스타일 속성들을 여기에 추가할 수 있습니다.
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${entry.value['time']?.split(' ').last}',
                        style: TextStyle(fontSize: 16, color: ftColor),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${entry.value['temperature']}',
                        style: TextStyle(fontSize: 16, color: ftColor),
                      ),
                      SizedBox(height: 20),
                      Icon(
                        icon,
                        size: 30,
                        color: ftColor,
                      ),
                      SizedBox(height: 40),
                      Text(
                        '${entry.value['skyStatus']}',
                        style: TextStyle(fontSize: 16, color: ftColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3), // 버튼 사이의 간격 조절
              ],
            );
          },
        ).toList(),
      ),
    );
  }
}