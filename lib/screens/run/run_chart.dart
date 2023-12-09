import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BarChartSample extends StatefulWidget {
  @override
  _BarChartSampleState createState() => _BarChartSampleState();
}

class _BarChartSampleState extends State<BarChartSample> {
  int _selectedChart = 0; // 선택된 차트 인덱스
  List<bool> isSelected = [true, false, false, false]; // 버튼 선택 상태
  double totalSum = 0.0; // 여기에 상태 변수 추가
  final storage = FlutterSecureStorage();
  late Map<int, double> weeklyData = {};
  late Map<int, double> monthlyData = {};
  late Map<int, double> yearlyData = {};
  late Map<int, double> wholeData = {};
  int walk = 0;
  int time = 0;
  int Kcal = 0;

  int selectedYear = DateTime.now().year; // 현재 년도
  int selectedMonth = DateTime.now().month; // 현재 월


  Future<Map<String, dynamic>> _getWeeklyData() async {
    String? accessToken = await storage.read(key: 'accessToken');
    DateTime today = DateTime.now();
    DateTime firstDayOfWeek;

    if (today.weekday == DateTime.monday) {
      firstDayOfWeek = today;
    } else {
      int daysToSubtract = today.weekday - DateTime.monday;
      firstDayOfWeek = today.subtract(Duration(days: daysToSubtract));
    }

    String startDate = "${firstDayOfWeek.year}-${firstDayOfWeek.month.toString().padLeft(2, '0')}-${firstDayOfWeek.day.toString().padLeft(2, '0')}";
    String endDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    String requestUrl = "$IP_address/api/exercise/weekly?startDate=$startDate&endDate=$endDate";

    try {
      final response = await http.get(Uri.parse(requestUrl),
        headers: {
      'Content-Type' : 'application/json',
      'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
      },);

      print(startDate);
      print(endDate);
      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        Map<int, double> weeklySteps = {};
        double totalWalk = 0;
        double totalTime = 0;
        double totalKcal = 0;

        for (var data in responseData) {
          DateTime date = DateTime.parse(data['date']);
          int weekdayIndex = date.weekday -1 ; // Dart의 DateTime에서 월요일은 1, 일요일은 7입니다.
          // 유효한 숫자인지 확인
          double steps = data['steps']?.toDouble() ?? 0.0;
          double durationMinutes = data['durationMinutes']?.toDouble() ?? 0.0;
          double caloriesBurned = data['caloriesBurned']?.toDouble() ?? 0.0;

          // 계산 로직에 NaN 또는 Infinity가 발생하지 않도록 검증
          double point = (steps * 0.1 + durationMinutes * 0.01).isNaN ? 0.0 : steps * 0.1 + durationMinutes * 0.01;
          point = double.parse(point.toStringAsFixed(1));
          weeklySteps[weekdayIndex] = point; // 요일에 해당하는 키에 steps 값을 할당합니다.
          totalWalk += steps?.toInt() ?? 0;
          totalTime += durationMinutes?.toInt() ?? 0;
          totalKcal += caloriesBurned?.toInt() ?? 0;
        }
        print(weeklySteps);

        return {
          'data': weeklySteps,
          'walk': totalWalk,
          'time': totalTime,
          'kcal': totalKcal
        };
      } else {
        throw Exception('Failed to load weekly data');
      }
    } catch (e) {
      print(e.toString());
      // 에러 처리 로직
      return {}; // 빈 맵 반환
    }
  }

  Future<Map<String, dynamic>> _getMonthlyData(int year, int month) async {

    String? accessToken = await storage.read(key: 'accessToken');

    String requestUrl = "$IP_address/api/exercise/monthly?year=$year&month=$month";

    try {
      final response = await http.get(Uri.parse(requestUrl),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
        },);

      print(year);
      print(month);
      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        Map<int, double> monthlySteps = {};
        double totalWalk = 0;
        double totalTime = 0;
        double totalKcal = 0;

        for (var data in responseData) {
          DateTime date = DateTime.parse(data['date']);
          int dayIndex = date.day - 1; // 달의 날짜 인덱스 (0부터 시작)

          double steps = data['steps']?.toDouble() ?? 0.0;
          double durationMinutes = data['durationMinutes']?.toDouble() ?? 0.0;
          double point = steps * 0.1 + durationMinutes * 0.01;
          double caloriesBurned = data['caloriesBurned']?.toDouble() ?? 0.0;
          point = double.parse(point.toStringAsFixed(1));

          monthlySteps[dayIndex] = point; // 해당 날짜에 대한 데이터를 매핑합니다.
          totalWalk += steps?.toInt() ?? 0;
          totalTime += durationMinutes?.toInt() ?? 0;
          totalKcal += caloriesBurned?.toInt() ?? 0;
        }
        print(monthlySteps);
        return {
          'data': monthlySteps,
          'walk': totalWalk,
          'time': totalTime,
          'kcal': totalKcal
        };
      } else {
        throw Exception('Failed to load weekly data');
      }
    } catch (e) {
      print(e.toString());
      return {};
    }
  }

  Future<Map<String, dynamic>> _getYearlyData(int year) async {

    String? accessToken = await storage.read(key: 'accessToken');
    String requestUrl = "$IP_address/api/exercise/yearly/$year";

    try {
      final response = await http.get(Uri.parse(requestUrl),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
        });

      print(year);
      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        Map<int, double> yearlySteps = {};
        double totalWalk = 0;
        double totalTime = 0;
        double totalKcal = 0;

        for (var key in responseData.keys) {
          List<String> dateParts = key.split('-');
          int monthIndex = int.parse(dateParts[1]) - 1;

          double steps = responseData[key]['steps']?.toDouble() ?? 0.0;
          double durationMinutes = responseData[key]['durationMinutes']?.toDouble() ?? 0.0;
          double point = steps * 0.1 + durationMinutes * 0.01;
          double caloriesBurned = responseData[key]['caloriesBurned']?.toDouble() ?? 0.0;

          yearlySteps[monthIndex] = point; // 해당 월에 대한 데이터를 매핑합니다.
          totalWalk += steps?.toInt() ?? 0;
          totalTime += durationMinutes?.toInt() ?? 0;
          totalKcal += caloriesBurned?.toInt() ?? 0;
        }

        return {
          'data': yearlySteps,
          'walk': totalWalk,
          'time': totalTime,
          'kcal': totalKcal
        };
      } else {
        throw Exception('Failed to load weekly data');
      }
    } catch (e) {
      print(e.toString());
      return {};
      // 에러 처리 로직
    }
  }

  Future<Map<String, dynamic>> _getWholeData() async {

    String? accessToken = await storage.read(key: 'accessToken');
    String requestUrl = "$IP_address/api/exercise/all";

    try {
      final response = await http.get(Uri.parse(requestUrl),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
        },);

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        double totalWalk = 0;
        double totalTime = 0;
        double totalKcal = 0;

        double steps = responseData['steps']?.toDouble() ?? 0.0;
        double durationMinutes = responseData['durationMinutes']?.toDouble() ?? 0.0;
        double caloriesBurned = responseData['caloriesBurned']?.toDouble() ?? 0.0;
        // 포인트 계산 로직 (예시: steps와 durationMinutes의 비율을 조정하여 포인트를 계산)
        double point = steps * 0.1 + durationMinutes * 0.01; // 소수점 첫째 자리까지
        Map<int, double> wholeSteps = {0: point};

        totalWalk += steps?.toInt() ?? 0;
        totalTime += durationMinutes?.toInt() ?? 0;
        totalKcal += caloriesBurned?.toInt() ?? 0;
        return {
          'data': wholeSteps,
          'walk': totalWalk,
          'time': totalTime,
          'kcal': totalKcal
        };;
      }
      else {
        throw Exception('Failed to load weekly data');
      }
    } catch (e) {
      print(e.toString());
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: 50),
        child: Column(
          children: [
            _buildButtonBar(),
            SizedBox(height: 10.0),// 버튼바를 구성하는 함
            Align(
              alignment: Alignment.centerLeft, // Aligns the _showInfo() widget to the left
              child: Padding(
                padding: EdgeInsets.only(left: 20), // Adjust the value as needed
                child: _showInfo(),
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 200, // 차트의 높이
              width: 400, // 차트의 너비
              child: _buildChart(_selectedChart), // 현재 선택된 차트
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }


  Widget _buildMonthSelector() {
    return _selectedChart == 1 ? Container(
      height: 44,
      width: 96,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey[200], // 변경된 배경색
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[400]!, width: 2), // 테두리 스타일 변경
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMonth,
          icon: Icon(Icons.arrow_drop_down, color: Colors.black, size: 30), // 아이콘 스타일 변경
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold), // 텍스트 스타일 변경
          dropdownColor: Colors.white,
          items: List<DropdownMenuItem<int>>.generate(12, (index) {
            return DropdownMenuItem<int>(
              value: index + 1,
              child: Text("${index + 1}월", style: TextStyle(color: Colors.black)),
            );
          }),
          onChanged: (int? newValue) {
            setState(() {
              if (newValue != null) {
                selectedMonth = newValue;
                _loadMonthlyData(DateTime.now().year, selectedMonth);
              }
            });
          },
        ),
      ),
    ) : Container();
  }

  void _loadChartData() async {
    switch (_selectedChart) {
      case 0:
        await _loadWeeklyData();
        break;
      case 1:
        await _loadMonthlyData(DateTime.now().year, selectedMonth);
        break;
      case 2:
        await _loadYearlyData(DateTime.now().year);
        break;
      case 3:
        await _loadWholeData();
        break;
      default:
        await _loadWeeklyData();
    }
  }

  Future<Map<String, dynamic>> _loadWeeklyData() async {
    try {
      var result = await _getWeeklyData();
      setState(() {
        weeklyData = result['data']  as Map<int, double>;
        totalSum = calculateSum(weeklyData);
        walk = (result['walk'] as double).toInt(); // double 타입에서 int 타입으로 변환
        time = (result['time'] as double).toInt(); // double 타입에서 int 타입으로 변환
        Kcal = (result['kcal'] as double).toInt(); // double 타입에서 int 타입으로 변환
      });
      return result;
    } catch (e) {
      print('Error loading weekly data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadMonthlyData(int year, int month) async {
    try {
      var result = await _getMonthlyData(year, month);
      setState(() {
        monthlyData = result['data']  as Map<int, double>;
        totalSum = calculateSum(monthlyData);
        walk = (result['walk'] as double).toInt(); // double 타입에서 int 타입으로 변환
        time = (result['time'] as double).toInt(); // double 타입에서 int 타입으로 변환
        Kcal = (result['kcal'] as double).toInt(); // double 타입에서 int 타입으로 변환

      });
      return result;
    }  catch (e) {
      print('Error loading weekly data: $e');
      return{};
    }
  }

  Future<Map<String, dynamic>> _loadYearlyData(int year) async {
    try {
    var result = await _getYearlyData(year);
    setState(() {
      yearlyData = result['data'] as Map<int, double>;
      totalSum = calculateSum(yearlyData);
      walk = (result['walk'] as double).toInt(); // double 타입에서 int 타입으로 변환
      time = (result['time'] as double).toInt(); // double 타입에서 int 타입으로 변환
      Kcal = (result['kcal'] as double).toInt(); // double 타입에서 int 타입으로 변환

    });
    return result;
    }  catch (e) {
      print('Error loading weekly data: $e');
      return{};
    }
  }

  Future<Map<String, dynamic>> _loadWholeData() async {
    try {
    var result = await _getWholeData();
    setState(() {
      wholeData = result['data']  as Map<int, double>;
      totalSum = calculateSum(wholeData);
      walk = (result['walk'] as double).toInt(); // double 타입에서 int 타입으로 변환
      time = (result['time'] as double).toInt(); // double 타입에서 int 타입으로 변환
      Kcal = (result['kcal'] as double).toInt(); // double 타입에서 int 타입으로 변환
    });
    return result;
    }  catch (e) {
      print('Error loading weekly data: $e');
      return{};
    }
  }

  double calculateSum(Map<int, double> data) {
    double sum = data.values.fold(0.0, (sum, item) => sum + item);
    // 소수점 첫째 자리까지만 표시
    return double.parse(sum.toStringAsFixed(1));
  }

  Widget _showInfo() {
    DateTime now = DateTime.now();
    Widget infoWidget;
    switch (_selectedChart) {
      case 0:
        infoWidget = Text(
          "이번 주",
          style: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
          ),
        );
        break;
      case 1:
        infoWidget = Row(
          children: <Widget>[
            Text(
              "${now.year}년도",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            _buildMonthSelector(),
          ],
        );
        break;
      case 2:
        infoWidget = Text(
          "${now.year}년도",
          style: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
          ),
        );
        break;
      case 3:
        infoWidget = Text(
          "총",
          style: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
          ),
        );
        break;
      default:
        infoWidget = Text(
          "이번 주",
          style: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
          ),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 여기를 추가
      children: <Widget>[
        Row(
          children: <Widget>[
            Row(
              children: <Widget>[
                infoWidget,
              ],
            ),
          ],
        ),
        Text(
          "$totalSum",
          style: GoogleFonts.anton(
            fontSize: 50.0,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          "포인트",
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            color: Colors.black38,
          ),
        ),
        SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 세로 정렬을 위한 설정
          children: [
            Row(
              children: [
                SizedBox(width: 10),
                Text(
                  "총 걸음수 ",
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "$walk",
                  style: GoogleFonts.anton(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), // 항목 간의 간격 추가
            Row(
              children: [
                SizedBox(width: 10),
                Text(
                  "총 산책 시간 ",
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "$time",
                  style: GoogleFonts.anton(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), // 항목 간의 간격 추가
            Row(
              children: [
                SizedBox(width: 10),
                Text(
                  "칼로리 ",
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "$Kcal",
                  style: GoogleFonts.anton(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildButtonBar() {
        return ToggleButtons(
      borderColor: Colors.transparent,
      fillColor: Color(0xFFFDD835), // 선택된 버튼의 배경색
      selectedBorderColor: Color(0xFFFDD835), // 선택된 버튼의 테두리 색
      borderWidth: 1,
      selectedColor: Colors.black, // 선택된 버튼의 글자색
      color: Colors.black, // 선택되지 않은 버튼의 글자색
      borderRadius: BorderRadius.circular(25), // 버튼의 둥근 모서리
      isSelected: isSelected, // 각 버튼의 선택 상태
      onPressed: (int index) {
        setState(() {
          for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
            isSelected[buttonIndex] = buttonIndex == index;
          }
          _selectedChart = index;
        });
        _loadChartData();
      },
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text('주'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text('월'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text('년'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text('전체'),
        ),
      ],
    );
  }

  void _updateChartData(Map<String, dynamic> result) {
    setState(() {
      if (result.isNotEmpty) {
        if (result.containsKey('data')) {
          var chartData = result['data'] as Map<int, double>;
          totalSum = calculateSum(chartData);

          if (result.containsKey('walk')) {
            walk = (result['walk'] as double).toInt();
          }
          if (result.containsKey('time')) {
            time = (result['time'] as double).toInt();
          }
          if (result.containsKey('kcal')) {
            Kcal = (result['kcal'] as double).toInt();
          }
        }
      }
    });
  }

  Widget _buildChart(int chartIndex) {
    Map<int, double> data;
    Widget chart;

    switch (chartIndex) {
      case 0:
      // 주별 데이터 설정

        data = weeklyData;
        chart = _buildWeeklyChart(data);
        break;

      case 1:
      // 월별 데이터 설정
        data = monthlyData;
        chart = _buildMonthlyChart(data, selectedYear, selectedMonth, DateTime(selectedYear, selectedMonth + 1, 0).day);
        break;

      case 2:
        data = yearlyData;
        chart = _buildYearlyChart(data);
        break;
      case 3:
        data = wholeData;
        chart = _buildWholeChart(data);
        break;
      default:
        data = weeklyData;
        chart = _buildWeeklyChart(data);
        break;
    }

    // 데이터 합계 계산
    double newTotalSum = calculateSum(data);

      setState(() {
        totalSum = newTotalSum;
      });
    return chart;
  }


  Widget _buildWeeklyChart(Map<int, double> data) {
    // 각 요일별 데이터 값
    final Map<int, double> weeklyData = data;

    // 요일 레이블
    final Map<int, String> dayLabels = {
      0: '월', 1: '화', 2: '수', 3: '목', 4: '금', 5: '토', 6: '일'
    };
    // 최대값을 계산합니다.
    final double maxValue = weeklyData.values.fold(0.0, (max, v) => v > max ? v : max);
    final double maxY = maxValue * 1.1;

    // 각 막대의 데이터를 생성합니다.
    final List<BarChartGroupData> barGroups = List.generate(7, (index) {
      final dataValue = weeklyData[index] ?? 0.0; // 요일별 데이터 값 또는 기본값
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            y: dataValue,
            colors: [Color(0xFFFDD835)],
            width: 16, // 막대의 두께
            borderRadius: BorderRadius.circular(4), // 둥근 모서리
          )
        ], // 첫 번째 막대에 대한 툴팁 인덱스
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
            show: true, // y축 그리드 라인을 표시합니다.
            checkToShowHorizontalLine: (value) =>
            value % 10000 == 0 // y축 그리드 라인이 각 5000 단위마다 표시되도록 합니다.
        ),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: SideTitles(showTitles: false),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitles: (value) {
              // maxY 값과 다른 y축 값들을 정수로 변환하여 반환
              return '${value.toInt()}';
            },
          ),
          topTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (double value) => dayLabels[value.toInt()] ?? '',
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }


  Widget _buildMonthlyChart(Map<int, double> data, int year, int month, int daysInMonth) {
    // 일별 데이터로 막대 차트 그룹 생성
    List<BarChartGroupData> barGroups = List.generate(daysInMonth, (index) {
      final dataValue = data[index] ?? 0.0; // 일별 데이터 값 또는 기본값
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
              y: dataValue,
              colors: [Color(0xFFFDD835)],
              width: 8, // 막대의 두께
              borderRadius: BorderRadius.circular(4)
          )
        ],
      );
    });

    final double maxValue = data.values.fold(0.0, (max, v) => v > max ? v : max);
    final double maxY = maxValue * 1.1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
            show: true,
            checkToShowHorizontalLine: (value) =>
            value % 10000 == 0
        ),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: SideTitles(showTitles: false),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitles: (value) => '${value.toInt()}',
          ),
          topTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (double value) {
              // 첫 날짜와 마지막 날짜, 그리고 각 주의 일요일 표시
              DateTime labelDate = DateTime(year, month, value.toInt() + 1);
              if (labelDate.day == 1 || labelDate.day == daysInMonth || labelDate.weekday == DateTime.sunday) {
                return '${labelDate.day}';
              }
              return '';
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }


  Widget _buildYearlyChart(Map<int, double> data) {
    final Map<int, String> monthLabels = {
      0: '1', 1: '2', 2: '3', 3: '4', 4: '5', 5: '6',
      6: '7', 7: '8', 8: '9', 9: '10', 10: '11', 11: '12'
    };

    // 각 월별 데이터 값
    final Map<int, double> monthlyData = data;
    final double maxValue = monthlyData.values.fold(0.0, (max, v) => v > max ? v : max);
    final double maxY = maxValue * 1.1;

    double newtotalSum = calculateSum(monthlyData);

    // 각 막대의 데이터를 생성합니다.
    final List<BarChartGroupData> barGroups = List.generate(12, (index) {
      final dataValue = monthlyData[index] ?? 0.0; // 월별 데이터 값 또는 기본값
      return BarChartGroupData(
          x: index,
          barRods: [BarChartRodData(y: dataValue, colors: [Color(0xFFFDD835)], width: 20, // 막대의 두께
              borderRadius: BorderRadius.circular(4))]
      );
    });

    setState(() {
      totalSum = newtotalSum; // 주별 데이터 합계를 저장
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
            show: true, // y축 그리드 라인을 표시합니다.
            checkToShowHorizontalLine: (value) =>
            value % 10000 == 0 // y축 그리드 라인이 각 5000 단위마다 표시되도록 합니다.
        ),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: SideTitles(showTitles: false),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitles: (value) {
              // maxY 값과 다른 y축 값들을 정수로 변환하여 반환
              return '${value.toInt()}';

            },
          ),
          topTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (double value) => monthLabels[value.toInt()] ?? '',
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups, // 생성된 barGroups을 사용합니다.
      ),
    );
  }

  Widget _buildWholeChart(Map<int, double> data) {
    // 연도별 데이터 값
    final Map<int, double> yearlyData = data;

    // 연도 레이블
    final Map<int, String> yearLabels = {
      0: '2023',
    };

    double newtotalSum = calculateSum(yearlyData);

    final double maxValue = yearlyData.values.fold(0.0, (max, v) => v > max ? v : max);
    final double maxY = maxValue * 1.1;

    // 각 막대의 데이터를 생성합니다.
    final List<BarChartGroupData> barGroups = List.generate(yearLabels.length, (index) {
      final dataValue = yearlyData[index] ?? 0.0; // 연도별 데이터 값 또는 기본값
      return BarChartGroupData(
          x: index,
          barRods: [BarChartRodData(y: dataValue, colors: [Color(0xFFFDD835)], width: 25, // 막대의 두께
              borderRadius: BorderRadius.circular(4))]
      );
    });


    setState(() {
      totalSum = newtotalSum; // 주별 데이터 합계를 저장
    });
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY, // y축 최대값
        minY: 0, // y축 최소값
        gridData: FlGridData(
            show: true, // y축 그리드 라인을 표시합니다.
            checkToShowHorizontalLine: (value) =>
            value % 20000 == 0 // y축 그리드 라인이 각 5000 단위마다 표시되도록 합니다.
        ),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: SideTitles(showTitles: false),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: 55,
            getTitles: (value) {
              // maxY 값과 다른 y축 값들을 정수로 변환하여 반환
              return '${value.toInt()}';
            },
          ),
          topTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (double value) => yearLabels[value.toInt()] ?? '',
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}