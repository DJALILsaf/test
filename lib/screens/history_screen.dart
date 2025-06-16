import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bulksmsv1/providers/message_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الرسائل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              // سيتم إضافة تصدير السجل لاحقاً
            },
          ),
        ],
      ),
      body: Consumer<MessageProvider>(
        builder: (context, provider, child) {
          if (provider.messageLogs.isEmpty) {
            return const Center(
              child: Text('لا يوجد سجل للرسائل'),
            );
          }

          return ListView.builder(
            itemCount: provider.messageLogs.length,
            itemBuilder: (context, index) {
              final log = provider.messageLogs[index];
              final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
              final status = log['status'] as String;
              Color statusColor;
              IconData statusIcon;

              switch (status) {
                case 'تم':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'فشل':
                  statusColor = Colors.red;
                  statusIcon = Icons.error;
                  break;
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.schedule;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(log['phoneNumber'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log['message'] as String),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(DateTime.parse(log['timestamp'] as String)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(color: statusColor),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 