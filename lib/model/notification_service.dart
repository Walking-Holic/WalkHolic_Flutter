import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // 싱글톤 패턴을 사용하기 위한 private static 변수
  static final NotificationService _instance = NotificationService._();
  // NotificationService 인스턴스 반환
  factory NotificationService() {
    return _instance;
  }

  // private 생성자
  NotificationService._();
  // 로컬 푸시 알림을 사용하기 위한 플러그인 인스턴스 생성
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  // 초기화 작업을 위한 메서드 정의
  Future<void> init() async {
    // 알림을 표시할 때 사용할 로고를 지정
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_launcher');


    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    // 안드로이드 플랫폼에서 사용할 초기화 설정
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsDarwin);


    // 채널 생성 추가
    const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
      'counter_channel', // 이 값은 앞서 언급한 값과 일치해야 합니다.
      'Counter Channel',
      description: 'This channel is used for counter-related notifications',
      importance: Importance.high,
      playSound: true,
    );

// iOS에서 채널을 등록합니다.
    var iosPlatformSpecificImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlatformSpecificImplementation != null) {
      await iosPlatformSpecificImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // 로컬 푸시 알림을 초기화
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('Notification Channel Initialized');
  }

  // 푸시 알림 권한 요청
  Future<PermissionStatus> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    return status;
  }

  // 푸시 알림 생성
  Future<void> scheduleNotification(tz.TZDateTime scheduledTime) async {
    const int notificationId = 0;

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'counter_channel',
      'Counter Channel',
      channelDescription:
      'This channel is used for counter-related notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    final tz.TZDateTime scheduledTimeZone = tz.TZDateTime(
      tz.getLocation('Asia/Seoul'),
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    print('Scheduled Notification Time: $scheduledTimeZone');

    // 여기서 푸시될 정보를 표시
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Walk Holic',
      '알람 설정한 산책 시간 입니다',
      scheduledTimeZone,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('Notification Scheduled');
  }
}