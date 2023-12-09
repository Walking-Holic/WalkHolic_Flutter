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
    AndroidInitializationSettings('drawable/splash');


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
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()!
        .requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 로컬 푸시 알림을 초기화
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('Notification Channel Initialized');
  }

  // Future<void> showNotification(int targetNumber) async {
  //   // 푸시 알림의 ID
  //   const int notificationId = 0;
  //   // 알림 채널 설정값 구성
  //   const AndroidNotificationDetails androidNotificationDetails =
  //   AndroidNotificationDetails(
  //     'counter_channel', // 알림 채널 ID
  //     'Counter Channel', // 알림 채널 이름
  //     channelDescription:
  //     'This channel is used for counter-related notifications',
  //     // 알림 채널 설명
  //     importance: Importance.high, // 알림 중요도
  //   );
  //   // 알림 상세 정보 설정
  //   const NotificationDetails notificationDetails =
  //   NotificationDetails(android: androidNotificationDetails);
  //   // 알림 보이기
  //   await flutterLocalNotificationsPlugin.show(
  //     notificationId, // 알림 ID
  //     '산책 시간 알림', // 알림 제목
  //     '설정하신 산책 시간이 다 되었습니다!', // 알림 메시지
  //     notificationDetails, // 알림 상세 정보
  //   );
  // }
  // 푸시 알림 권한 요청
  Future<PermissionStatus> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    return status;
  }

  // 푸시 알림 생성
  Future<void> scheduleNotification(DateTime scheduledTime) async {
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
      '잠깐 시간 될까',
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