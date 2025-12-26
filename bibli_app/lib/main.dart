import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bibli_app/core/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bibli_app/core/services/cache_service.dart';
import 'package:bibli_app/core/services/monitoring_service.dart';
import 'package:bibli_app/core/services/notification_service.dart';



class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        MonitoringService.logEvent('app_resumed', null);
        break;
      case AppLifecycleState.paused:
        MonitoringService.logAppBackground();
        break;
      case AppLifecycleState.detached:
        MonitoringService.logEvent('app_detached', null);
        break;
      default:
        break;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    AppConfig.ensureSupabaseConfig();

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    void scheduleBackgroundServices() {
      // Inicializar serviços em background
      Future.microtask(() async {
        try {
          await MonitoringService.initialize();
          CacheService.autoCleanup();
          await MonitoringService.logAppLaunch();
          await NotificationService.initAndScheduleDailyReading();
          WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
        } catch (e) {
          debugPrint('Erro ao inicializar serviços: $e');
        }
      });
    }

    runApp(const BibliApp());
    scheduleBackgroundServices();
  } catch (e, stack) {
    debugPrint('Erro fatal: $e');
    debugPrint('Stack: $stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erro ao inicializar app: $e'),
        ),
      ),
    ));
  }
}
