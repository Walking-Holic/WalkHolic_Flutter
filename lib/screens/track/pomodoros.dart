import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/model/rank_image.dart';
import 'package:fresh_store_ui/screens/run/run_chart.dart';
import 'package:fresh_store_ui/screens/tabbar/tabbar.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sensors/sensors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';

import '../../constants.dart';

class PedometerAndStopwatchUI extends StatefulWidget {
  @override
  _PedometerAndStopwatchUIState createState() =>
      _PedometerAndStopwatchUIState();
}

class _PedometerAndStopwatchUIState extends State<PedometerAndStopwatchUI> {
  bool _isPlaying = false;
  bool _isPaused = false;
  Timer? _timer;
  int walk = 0;
  int time = 0;
  int newwalk = 0;
  int newtime = 0;
  String? nickname;
  String? rank;
  String? newRank;


  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (!_isPaused && event.x > 10) {
        setState(() => walk++);
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final storage = FlutterSecureStorage();

    try {// 로딩 시작
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/member/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = response.data;

        setState(() {
          rank = responseData['rank'];
        });
      } else {
        // 에러 처리
        print('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }


  Future<void> _loadNewProfile() async {
    final storage = FlutterSecureStorage();

    try {// 로딩 시작
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/member/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = response.data;

        setState(() {
          newRank = responseData['rank'];
        });
      } else {
        // 에러 처리
        print('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }


  void _startStopwatch() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        time++;
      });
    });
  }

  void _stopStopwatch() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _resetStopwatch() {
    _stopStopwatch();
    setState(() {
      time = 0;
    });
  }

  @override
  void dispose() {
    _stopStopwatch();
    super.dispose();
  }

  void _resetWalk() {
    setState(() {
      // 산책 관련 상태를 초기화합니다.
      _isPlaying = false;
      _isPaused = false;
      walk = 0;
      // 기타 산책 관련 상태 변수들도 여기에서 초기화할 수 있습니다.
    });
  }

  Future<void> _saveResult(String date, int steps, int durationMinutes, int caloriesBurned) async {
    final url = Uri.parse('$IP_address/api/exercise/save');
    try {
      String? accessToken = await storage.read(key: 'accessToken');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
        },
        body: json.encode({
          'date': date,
          'steps': steps,
          'durationMinutes': durationMinutes,
          'caloriesBurned': caloriesBurned,
        }),
      );

      if (response.statusCode == 200) {
        print('Data saved successfully');
      } else {
        print('Failed to save data');
      }
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<Map<String, dynamic>> _sendDataToServer() async {
    final url = Uri.parse('$IP_address/api/member/update/rank');
    Map<String, dynamic> result = {};

    try {
      String? accessToken = await storage.read(key: 'accessToken');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
        },
        body: json.encode({
          'time': newtime,
          'walk': newwalk,
        }),
      );
      print("시간 : $newtime");
      print("걸음 : $newwalk");
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        result = json.decode(response.body);
        print('Data sent successfully');

        print('Data sent successfully');
      } else {
        print('Failed to send data');
      }
    } catch (e) {
      print('Error sending data: $e');
      result = {'error': e.toString()};
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    String formattedTime = DateFormat('mm:ss').format(DateTime(0, 0, 0, 0, 0, time));

    return Scaffold(
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: Color(0xFFF4EDDB),
          child: SizedBox(
            height: screenHeight,
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: 16),
                  Icon(Icons.directions_walk, size: 100),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      formattedTime, // 스탑워치 시간을 표시할 문자열
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 70),
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Visibility(
                        visible: !_isPlaying,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: _buildPlayButton(),
                      ),
                      Visibility(
                        visible: _isPlaying,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: _buildControlButtons(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 1.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          '진정 위대한 모든 생각은 걷기에서 나온다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 64.4),
                  _buildStepCounterCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Visibility(
      visible: !_isPlaying,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: IconButton(
        icon: Icon(Icons.play_circle, color: Colors.black),
        iconSize: 100,
        onPressed: () {
          setState(() {
            _isPlaying = true;
            _startStopwatch();
          });
        },
      ),
    );
  }

  Widget _buildControlButtons() {
    return Visibility(
      visible: _isPlaying,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: ButtonBar(
        alignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(
              _isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled,
              color: Colors.black,
            ),
            iconSize: 100,
            onPressed: () {
              setState(() {
                _isPaused = !_isPaused; // 일시정지 상태를 전환합니다.
                if (_isPaused) {
                  _stopStopwatch();
                } else {
                  _startStopwatch(); // 타이머를 재개합니다.
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.stop_circle, color: Colors.black),
            iconSize: 100,
            onPressed: () {
              _stopStopwatch();
              _showExitConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> someFunction() async {
    Map<String, dynamic> serverResponse = await _sendDataToServer();
    print(serverResponse); // 서버 응답 출력

    if (serverResponse['updated'] == true) {
      await _loadNewProfile();
      await _showRankUpDialog(rank ?? 'default', newRank ?? 'default');
    }
    await _saveResult(serverResponse['date'],
        serverResponse['steps'],
        serverResponse['durationMinutes'],
        serverResponse['caloriesBurned']);
  }

  Future<void> _showRankUpDialog(String oldRank, String newRank) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('등급 상승!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('당신의 등급이 $oldRank에서 $newRank로 상승했습니다!'),
              SizedBox(height: 20),
              AnimatedSwitcher(
                duration: Duration(seconds: 2),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                      scale: animation,
                      child: child
                  );
                },
                child: Container(
                  key: ValueKey(newRank), // key를 Container에 적용
                  child: RankImage.getRankImage(newRank, width: 70, height: 70),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
              },
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF4EDDB),
          title: Center(
            child: Text(
                '측정 종료',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)
            ),
          ),
          content: Text('측정을 종료 할까요?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          actions: <Widget>[
            TextButton(
              child: Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              onPressed: () async {
                newwalk = walk;
                newtime = time;
                _resetStopwatch();
                _resetWalk();
                await someFunction();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FRTabbarScreen(initialTabIndex: 3)),
                );
              },
            ),
            TextButton(
              child: Text('취소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자를 닫습니다.
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepCounterCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Colors.black,
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Walk',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFFF4EDDB)),
            ),
            Text(
              '$walk', // 여기에 걸음 수 데이터를 연동하세요
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Color(0xFFF4EDDB)),
            ),
          ],
        ),
      ),
    );
  }
}