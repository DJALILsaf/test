import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:bulksmsv1/models/scheduled_message.dart';
import 'package:bulksmsv1/services/message_service.dart';

class SchedulingService {
  static final SchedulingService _instance = SchedulingService._internal();
  factory SchedulingService() => _instance;
  SchedulingService._internal();

  late Database _database;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final _uuid = const Uuid();

  Future<void> initialize() async {
    // تهيئة قاعدة البيانات
    _database = await openDatabase(
      join(await getDatabasesPath(), 'scheduled_messages.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scheduled_messages(
            id TEXT PRIMARY KEY,
            phoneNumbers TEXT NOT NULL,
            message TEXT NOT NULL,
            scheduledTime TEXT NOT NULL,
            type TEXT NOT NULL,
            isSent INTEGER NOT NULL,
            error TEXT
          )
        ''');
      },
      version: 1,
    );

    // تهيئة الإشعارات المحلية
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // تهيئة المناطق الزمنية
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // TODO: معالجة النقر على الإشعار
  }

  Future<String> scheduleMessage({
    required List<String> phoneNumbers,
    required String message,
    required DateTime scheduledTime,
    required String type,
  }) async {
    final id = _uuid.v4();
    final scheduledMessage = ScheduledMessage(
      id: id,
      phoneNumbers: phoneNumbers,
      message: message,
      scheduledTime: scheduledTime,
      type: type,
    );

    // حفظ الرسالة في قاعدة البيانات
    await _database.insert(
      'scheduled_messages',
      scheduledMessage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // تحويل التاريخ والوقت إلى المنطقة الزمنية المحلية
    final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

    // جدولة الإشعار
    await _notifications.zonedSchedule(
      id.hashCode,
      'رسالة مجدولة',
      'حان وقت إرسال الرسالة المجدولة',
      scheduledTz,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_messages',
          'الرسائل المجدولة',
          channelDescription: 'إشعارات الرسائل المجدولة',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: id,
    );

    return id;
  }

  Future<List<ScheduledMessage>> getScheduledMessages() async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'scheduled_messages',
      orderBy: 'scheduledTime DESC',
    );

    return List.generate(maps.length, (i) => ScheduledMessage.fromMap(maps[i]));
  }

  Future<void> cancelScheduledMessage(String id) async {
    await _notifications.cancel(id.hashCode);
    await _database.delete(
      'scheduled_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markMessageAsSent(String id, {String? error}) async {
    await _database.update(
      'scheduled_messages',
      {
        'isSent': 1,
        'error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> processScheduledMessages() async {
    final now = DateTime.now();
    final messages = await getScheduledMessages();
    
    for (final message in messages) {
      if (!message.isSent && message.scheduledTime.isBefore(now)) {
        try {
          for (final number in message.phoneNumbers) {
            Map<String, dynamic> result;
            switch (message.type) {
              case 'sms':
                result = await MessageService.sendSms(
                  phoneNumber: number,
                  message: message.message,
                );
                break;
              case 'whatsapp':
                result = await MessageService.sendWhatsApp(
                  phoneNumber: number,
                  message: message.message,
                );
                break;
              case 'telegram':
                result = await MessageService.sendTelegram(
                  phoneNumber: number,
                  message: message.message,
                );
                break;
              default:
                result = {'success': false, 'error': 'طريقة إرسال غير صالحة'};
            }

            if (!result['success']) {
              await markMessageAsSent(message.id, error: result['error']);
              break;
            }
          }
          await markMessageAsSent(message.id);
        } catch (e) {
          await markMessageAsSent(message.id, error: e.toString());
        }
      }
    }
  }
} 