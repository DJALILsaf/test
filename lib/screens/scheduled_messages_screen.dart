import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bulksmsv1/providers/message_provider.dart';
import 'package:bulksmsv1/models/scheduled_message.dart';
import 'package:intl/intl.dart';

class ScheduledMessagesScreen extends StatelessWidget {
  const ScheduledMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل المجدولة'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ScheduledMessage>>(
        future: Provider.of<MessageProvider>(context, listen: false).getScheduledMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ: ${snapshot.error}'),
            );
          }

          final messages = snapshot.data ?? [];
          if (messages.isEmpty) {
            return const Center(
              child: Text('لا توجد رسائل مجدولة'),
            );
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    '${message.phoneNumbers.length} رقم - ${DateFormat('yyyy/MM/dd HH:mm').format(message.scheduledTime)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    message.type == 'sms' ? 'رسالة نصية' :
                    message.type == 'whatsapp' ? 'واتساب' : 'تيليجرام',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الرسالة: ${message.message}'),
                          const SizedBox(height: 8),
                          Text('الحالة: ${message.isSent ? 'تم الإرسال' : 'قيد الانتظار'}'),
                          if (message.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'الخطأ: ${message.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!message.isSent)
                                TextButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('إلغاء الجدولة'),
                                        content: const Text('هل أنت متأكد من إلغاء هذه الرسالة المجدولة؟'),
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
                                    if (confirmed == true) {
                                      await Provider.of<MessageProvider>(context, listen: false)
                                          .cancelScheduledMessage(message.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('تم إلغاء الرسالة المجدولة')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('إلغاء الجدولة'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 