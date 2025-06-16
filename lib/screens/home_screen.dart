import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bulksmsv1/providers/message_provider.dart';
import 'package:bulksmsv1/screens/history_screen.dart';
import 'package:bulksmsv1/screens/scheduled_messages_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, provider, _) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text('إرسال الرسائل الجماعية'),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduledMessagesScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (provider.error != null)
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: provider.clearError,
                                color: Colors.red.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'اختيار ملف Excel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: provider.isLoading || provider.isSending
                                  ? null
                                  : () => provider.pickAndParseExcel(),
                              icon: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(
                                provider.isLoading
                                    ? provider.currentOperation ?? 'جاري التحميل...'
                                    : 'اختر ملف Excel',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (provider.phoneNumbers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'اختيار العمود',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: provider.selectedColumn,
                                    onChanged: provider.isSending
                                        ? null
                                        : (value) {
                                            if (value != null) {
                                              provider.setSelectedColumn(value);
                                            }
                                          },
                                    items: List.generate(
                                      26,
                                      (index) => DropdownMenuItem(
                                        value: String.fromCharCode(65 + index),
                                        child: Text(
                                            'العمود ${String.fromCharCode(65 + index)}'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'عدد الأرقام: ${provider.phoneNumbers.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!provider.isSending)
                                    TextButton.icon(
                                      onPressed: provider.clearPhoneNumbers,
                                      icon: const Icon(Icons.clear_all),
                                      label: const Text('مسح الأرقام'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: provider.phoneNumbers.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(provider.phoneNumbers[index]),
                                      trailing: !provider.isSending
                                          ? IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () => _showEditPhoneDialog(
                                                context,
                                                provider,
                                                index,
                                              ),
                                            )
                                          : null,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'نص الرسالة',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!provider.isSending)
                                    TextButton.icon(
                                      onPressed: provider.clearMessage,
                                      icon: const Icon(Icons.clear),
                                      label: const Text('مسح النص'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                maxLines: 5,
                                enabled: !provider.isSending,
                                decoration: const InputDecoration(
                                  hintText: 'اكتب نص الرسالة هنا...',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: provider.setMessage,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: provider.isSending ||
                                              provider.phoneNumbers.isEmpty ||
                                              provider.message.isEmpty
                                          ? null
                                          : () => _showSendMethodDialog(
                                                context,
                                                provider,
                                              ),
                                      icon: const Icon(Icons.send),
                                      label: const Text('إرسال فوري'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: provider.isSending ||
                                              provider.phoneNumbers.isEmpty ||
                                              provider.message.isEmpty
                                          ? null
                                          : () => _showScheduleDialog(
                                                context,
                                                provider,
                                              ),
                                      icon: const Icon(Icons.schedule),
                                      label: const Text('جدولة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (provider.isSending)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            provider.currentOperation ?? 'جاري الإرسال...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showScheduleDialog(BuildContext context, MessageProvider provider) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('جدولة الإرسال'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('التاريخ'),
                subtitle: Text(
                  '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('الوقت'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final scheduledTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                Navigator.pop(context);
                _showSendMethodDialog(
                  context,
                  provider,
                  scheduledTime: scheduledTime,
                );
              },
              child: const Text('التالي'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendMethodDialog(
    BuildContext context,
    MessageProvider provider, {
    DateTime? scheduledTime,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(scheduledTime != null ? 'اختر طريقة الإرسال' : 'اختر طريقة الإرسال'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.blue),
              title: const Text('رسالة نصية (SMS)'),
              onTap: () {
                Navigator.pop(context);
                if (scheduledTime != null) {
                  provider.scheduleMessage(
                    context: context,
                    scheduledTime: scheduledTime,
                    type: 'sms',
                  );
                } else {
                  provider.sendMessages(context, 'sms');
                }
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.whatsapp,
                  color: Colors.green),
              title: const Text('WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                if (scheduledTime != null) {
                  provider.scheduleMessage(
                    context: context,
                    scheduledTime: scheduledTime,
                    type: 'whatsapp',
                  );
                } else {
                  provider.sendMessages(context, 'whatsapp');
                }
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.telegram,
                  color: Colors.blue),
              title: const Text('Telegram'),
              onTap: () {
                Navigator.pop(context);
                if (scheduledTime != null) {
                  provider.scheduleMessage(
                    context: context,
                    scheduledTime: scheduledTime,
                    type: 'telegram',
                  );
                } else {
                  provider.sendMessages(context, 'telegram');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context, MessageProvider provider, int index) {
    final controller = TextEditingController(text: provider.phoneNumbers[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل رقم الهاتف'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'أدخل رقم الهاتف',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newNumber = controller.text.trim();
              if (newNumber.isNotEmpty) {
                provider.editPhoneNumber(index, newNumber);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
} 