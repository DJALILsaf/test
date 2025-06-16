import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class MessageService {
  static Future<Map<String, dynamic>> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // تنظيف رقم الهاتف
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanNumber.isEmpty) {
        return {'success': false, 'error': 'رقم الهاتف غير صالح'};
      }

      // التحقق من صلاحية الإذن
      final status = await Permission.sms.request();
      if (status.isDenied) {
        return {'success': false, 'error': 'تم رفض إذن إرسال الرسائل النصية'};
      }

      // إرسال الرسالة باستخدام flutter_sms
      final String result = await sendSMS(
        message: message,
        recipients: [cleanNumber],
        sendDirect: true,
      );

      if (result == null) {
        return {'success': true, 'message': 'تم إرسال الرسالة بنجاح'};
      } else {
        return {'success': false, 'error': result};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // تنظيف رقم الهاتف
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanNumber.isEmpty) {
        return {'success': false, 'error': 'رقم الهاتف غير صالح'};
      }

      // إنشاء رابط واتساب
      final url = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return {'success': true, 'message': 'تم فتح واتساب بنجاح'};
      } else {
        return {'success': false, 'error': 'لا يمكن فتح واتساب'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendTelegram({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // تنظيف رقم الهاتف
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanNumber.isEmpty) {
        return {'success': false, 'error': 'رقم الهاتف غير صالح'};
      }

      // إنشاء رابط تيليجرام
      final url = Uri.parse('https://t.me/$cleanNumber?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return {'success': true, 'message': 'تم فتح تيليجرام بنجاح'};
      } else {
        return {'success': false, 'error': 'لا يمكن فتح تيليجرام'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
} 