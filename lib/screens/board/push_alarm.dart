import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fresh_store_ui/model/notification_service.dart';

class AlarmHomeScreen extends StatefulWidget {
  const AlarmHomeScreen({Key? key}) : super(key: key);

  @override
  AlarmHomeScreenState createState() => AlarmHomeScreenState();
}

class AlarmHomeScreenState extends State<AlarmHomeScreen> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    _requestNotificationPermissions();
    _selectedTime = TimeOfDay.now();

    // WidgetsBinding을 사용하여 위젯 트리가 완전히 구축된 후 _selectTime 함수를 호출합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectTime(context);
    });
  }

  void _requestNotificationPermissions() async {
    final status = await NotificationService().requestNotificationPermissions();
    print('Notification Permission Status: $status');
    if (status.isDenied && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('알림 권한이 거부되었습니다.'),
          content: Text('알림을 받으려면 앱 설정에서 권한을 허용해야 합니다.'),
          actions: <Widget>[
            TextButton(
              child: Text('설정'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }


  Future<void> _scheduleNotification(DateTime scheduledTime) async {
    // 권한 확인
    var status = await Permission.scheduleExactAlarm.status;
    print('Notification Permission status: $status');

    if (status.isGranted) {
      // 알림 스케줄링
      NotificationService().scheduleNotification(
          scheduledTime
      );
    } else {
      // 권한이 없으면 권한 요청
      var result = await Permission.scheduleExactAlarm.request();
      if (result.isGranted) {
        // 권한 허용 시 알림 스케줄링
        NotificationService().scheduleNotification(
            scheduledTime
        );
      } else {
        // 권한 거부 시 처리 (예: 사용자에게 권한 필요 메시지 표시)
        print('Notification Permission denied');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('푸시 알림 설정')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('알림 시간 선택: '),
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  child: const Text('선택'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // void _toggleTimer() {
  //   if (_timer?.isActive == true) {
  //     _stopTimer();
  //   } else {
  //     _startTimer();
  //   }
  // }

  // void _startTimer() {
  //   _timer = Timer.periodic(const Duration(seconds: 1), (_) {
  //     setState(() {
  //       _counter++;
  //       if (_counter == _selectedTime.hour * 3600 + _selectedTime.minute * 60) {
  //         _scheduleNotification();
  //         _stopTimer();
  //       }
  //     });
  //   });
  // }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      // TimeOfDay를 DateTime으로 변환
      final now = DateTime.now();
      DateTime selectedDateTime;

      // 현재 시간의 이전 시간으로 설정
      final pickedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      if (pickedDateTime.isBefore(now)) {
        // 예를 들어, 현재 시간이 10:30이고 사용자가 09:00으로 설정하면
        // 알림은 내일 09:00에 예약됩니다.
        selectedDateTime = pickedDateTime.add(Duration(days: 1));
      } else {
        selectedDateTime = pickedDateTime;
      }

      print('선택한 알림 시간: $selectedDateTime');
      print('현재 시각: $now');

      setState(() {
        _selectedTime = picked;
        _scheduleNotification(selectedDateTime);
      });
    }
  }


}