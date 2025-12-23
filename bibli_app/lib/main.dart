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
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';



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
  await dotenv.load(fileName: ".env");

  await SentryFlutter.init(
    (options) {
      final dsn = AppConfig.sentryDsn;
      if (dsn.isNotEmpty) {
        options.dsn = dsn;
      }
      options.environment = kDebugMode ? 'development' : 'production';
      options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
    },
    appRunner: () => runZonedGuarded(
      () async {
        // Configurar orientação
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        AppConfig.ensureSupabaseConfig();

        // Configurar error handling
        FlutterError.onError = (errorDetails) {
          MonitoringService.recordError(
            errorDetails.exception,
            errorDetails.stack,
            context: 'flutter_error',
          );
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          MonitoringService.recordError(error, stack, context: 'platform_error');
          return true;
        };

        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );

        // Inicializar serviços
        await MonitoringService.initialize();
        CacheService.autoCleanup();
        await MonitoringService.logAppLaunch();
        await NotificationService.initAndScheduleDailyReading();
        
        // Configurar lifecycle callbacks
        WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

        runApp(const BibliApp());
      },
      (error, stack) {
        MonitoringService.recordError(error, stack, context: 'main_zone');
      },
    ),
  );
}
