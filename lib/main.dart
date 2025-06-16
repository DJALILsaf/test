import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bulksmsv1/providers/message_provider.dart';
import 'package:bulksmsv1/screens/home_screen.dart';
import 'package:bulksmsv1/services/scheduling_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة خدمة الجدولة
  final schedulingService = SchedulingService();
  await schedulingService.initialize();
  
  // بدء معالجة الرسائل المجدولة
  schedulingService.processScheduledMessages();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: MaterialApp(
        title: 'Bulk SMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.blueAccent,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'SA'),
        ],
        locale: const Locale('ar', 'SA'),
        home: const HomeScreen(),
      ),
    );
  }
} 