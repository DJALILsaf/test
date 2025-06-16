import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bulksmsv1/services/message_service.dart';
import 'package:bulksmsv1/services/scheduling_service.dart';
import 'package:bulksmsv1/models/scheduled_message.dart';
import 'package:intl/intl.dart';

class MessageProvider with ChangeNotifier {
  List<String> _phoneNumbers = [];
  String _message = '';
  String _selectedColumn = 'A';
  bool _isLoading = false;
  String? _error;
  final List<Map<String, dynamic>> _messageLogs = [];
  bool _isSending = false;
  String? _currentOperation;

  final _schedulingService = SchedulingService();

  // Getters
  List<String> get phoneNumbers => List.unmodifiable(_phoneNumbers);
  String get message => _message;
  String get selectedColumn => _selectedColumn;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  List<Map<String, dynamic>> get messageLogs => List.unmodifiable(_messageLogs);
  String? get currentOperation => _currentOperation;

  // Setters
  void setMessage(String value) {
    if (_isSending) return;
    _message = value;
    notifyListeners();
  }

  void setSelectedColumn(String column) {
    if (_isSending) return;
    _selectedColumn = column;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setLoading(bool loading, {String? operation}) {
    _isLoading = loading;
    _currentOperation = operation;
    if (!loading) _currentOperation = null;
    notifyListeners();
  }

  void _setSending(bool sending) {
    _isSending = sending;
    notifyListeners();
  }

  // Methods
  Future<void> pickAndParseExcel() async {
    try {
      _setLoading(true, operation: 'جاري تحميل الملف...');
      _setError(null);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) {
        _setError('تم إلغاء اختيار الملف');
        return;
      }

      var bytes = result.files.first.bytes;
      if (bytes == null) {
        _setError('فشل في قراءة الملف');
        return;
      }

      _setLoading(true, operation: 'جاري تحليل البيانات...');
      var excel = Excel.decodeBytes(bytes);
      _phoneNumbers = [];
      
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        int columnIndex = _selectedColumn.codeUnitAt(0) - 'A'.codeUnitAt(0);
        
        for (var row in sheet.rows) {
          if (row.length > columnIndex && row[columnIndex]?.value != null) {
            String value = row[columnIndex]!.value.toString();
            if (_isValidPhoneNumber(value)) {
              _phoneNumbers.add(value);
            }
          }
        }
      }

      if (_phoneNumbers.isEmpty) {
        _setError('لم يتم العثور على أرقام هواتف صالحة في العمود المحدد');
      } else {
        _setError(null);
      }
    } catch (e) {
      _setError('حدث خطأ أثناء قراءة الملف: $e');
    } finally {
      _setLoading(false);
    }
  }

  bool _isValidPhoneNumber(String number) {
    // تنظيف الرقم من أي رموز غير رقمية
    String cleanNumber = number.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // التحقق من طول الرقم (بما في ذلك رمز الدولة)
    if (cleanNumber.length < 10 || cleanNumber.length > 15) {
      return false;
    }

    // التحقق من أن الرقم يبدأ بـ + أو رقم
    if (!cleanNumber.startsWith('+') && !RegExp(r'^[0-9]').hasMatch(cleanNumber)) {
      return false;
    }

    return true;
  }

  Future<void> sendMessages(BuildContext context, String type) async {
    if (_phoneNumbers.isEmpty || _message.isEmpty) {
      MessageService.showSnackBar(
        context,
        'يرجى اختيار الأرقام وإدخال نص الرسالة',
        isError: true,
      );
      return;
    }

    final confirmed = await MessageService.showConfirmationDialog(
      context,
      'تأكيد الإرسال',
      'هل أنت متأكد من إرسال الرسالة إلى ${_phoneNumbers.length} رقم؟',
    );

    if (!confirmed) return;

    _setSending(true);
    _setError(null);

    int successCount = 0;
    int failCount = 0;
    String? lastError;

    for (int i = 0; i < _phoneNumbers.length; i++) {
      String number = _phoneNumbers[i];
      _currentOperation = 'جاري إرسال الرسالة ${i + 1} من ${_phoneNumbers.length}';
      notifyListeners();

      Map<String, dynamic> result;
      
      try {
        switch (type) {
          case 'sms':
            result = await MessageService.sendSms(
              phoneNumber: number,
              message: _message,
            );
            break;
          case 'whatsapp':
            result = await MessageService.sendWhatsApp(
              phoneNumber: number,
              message: _message,
            );
            break;
          case 'telegram':
            result = await MessageService.sendTelegram(
              phoneNumber: number,
              message: _message,
            );
            break;
          default:
            result = {'success': false, 'error': 'طريقة إرسال غير صالحة'};
        }

        await saveMessageLog(
          phoneNumber: number,
          message: _message,
          status: result['success'] ? 'تم' : 'فشل',
          error: result['error'],
        );

        if (result['success']) {
          successCount++;
        } else {
          failCount++;
          lastError = result['error'];
        }
      } catch (e) {
        failCount++;
        lastError = e.toString();
        await saveMessageLog(
          phoneNumber: number,
          message: _message,
          status: 'فشل',
          error: e.toString(),
        );
      }
    }

    _setSending(false);
    _currentOperation = null;

    String resultMessage = 'تم إرسال $successCount رسالة بنجاح';
    if (failCount > 0) {
      resultMessage += ' وفشل إرسال $failCount رسالة';
      if (lastError != null) {
        resultMessage += '\nآخر خطأ: $lastError';
      }
    }

    MessageService.showSnackBar(
      context,
      resultMessage,
      isError: failCount > 0,
    );
  }

  Future<void> saveMessageLog({
    required String phoneNumber,
    required String message,
    required String status,
    String? error,
  }) async {
    final log = {
      'phoneNumber': phoneNumber,
      'message': message,
      'status': status,
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _messageLogs.insert(0, log);
    notifyListeners();

    // TODO: حفظ السجل في قاعدة البيانات المحلية
  }

  void clearError() {
    _setError(null);
  }

  void clearMessage() {
    if (_isSending) return;
    _message = '';
    notifyListeners();
  }

  void clearPhoneNumbers() {
    if (_isSending) return;
    _phoneNumbers.clear();
    notifyListeners();
  }

  void editPhoneNumber(int index, String newNumber) {
    if (_isSending) return;
    if (index >= 0 && index < _phoneNumbers.length) {
      if (_isValidPhoneNumber(newNumber)) {
        _phoneNumbers[index] = newNumber;
        notifyListeners();
      } else {
        _setError('رقم الهاتف غير صالح');
      }
    }
  }

  Future<void> scheduleMessage({
    required BuildContext context,
    required DateTime scheduledTime,
    required String type,
  }) async {
    if (_phoneNumbers.isEmpty || _message.isEmpty) {
      MessageService.showSnackBar(
        context,
        'يرجى اختيار الأرقام وإدخال نص الرسالة',
        isError: true,
      );
      return;
    }

    final confirmed = await MessageService.showConfirmationDialog(
      context,
      'تأكيد الجدولة',
      'هل أنت متأكد من جدولة الرسالة لإرسالها في ${DateFormat('yyyy/MM/dd HH:mm').format(scheduledTime)}؟',
    );

    if (!confirmed) return;

    try {
      await _schedulingService.scheduleMessage(
        phoneNumbers: _phoneNumbers,
        message: _message,
        scheduledTime: scheduledTime,
        type: type,
      );

      MessageService.showSnackBar(
        context,
        'تم جدولة الرسالة بنجاح',
      );
    } catch (e) {
      MessageService.showSnackBar(
        context,
        'حدث خطأ أثناء جدولة الرسالة: $e',
        isError: true,
      );
    }
  }

  Future<List<ScheduledMessage>> getScheduledMessages() async {
    try {
      return await _schedulingService.getScheduledMessages();
    } catch (e) {
      _setError('حدث خطأ أثناء جلب الرسائل المجدولة: $e');
      return [];
    }
  }

  Future<void> cancelScheduledMessage(String id) async {
    try {
      await _schedulingService.cancelScheduledMessage(id);
    } catch (e) {
      _setError('حدث خطأ أثناء إلغاء الرسالة المجدولة: $e');
    }
  }
} 