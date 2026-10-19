import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'models/app_config.dart';
import 'screens/pantalla_principal.dart';
import 'services/config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'cr.montededios.mddradio.audio',
    androidNotificationChannelName: 'Radio en vivo',
    androidNotificationOngoing: true,
  );
  try {
    await ConfigService.instancia.iniciar();
  } catch (e) {
    debugPrint('No se pudo iniciar la configuración: $e');
  }
  runApp(const MddRadioApp());
}

class MddRadioApp extends StatelessWidget {
  const MddRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppConfig?>(
      valueListenable: ConfigService.instancia.config,
      builder: (context, config, _) {
        final principal = config?.colorPrincipal ?? const Color(0xFFE3121C);
        final fondo = config?.colorFondo ?? const Color(0xFF0B0B0D);
        final esquema = ColorScheme.fromSeed(
          seedColor: principal,
          brightness: Brightness.dark,
        ).copyWith(primary: principal, onPrimary: Colors.white, surface: fondo);

        return MaterialApp(
          title: config?.nombre ?? 'MDD Radio HD',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: esquema,
            scaffoldBackgroundColor: fondo,
            appBarTheme: AppBarTheme(
              backgroundColor: fondo,
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
          ),
          home: config == null
              ? const _PantallaSinConfiguracion()
              : PantallaPrincipal(config: config),
        );
      },
    );
  }
}

class _PantallaSinConfiguracion extends StatelessWidget {
  const _PantallaSinConfiguracion();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No se pudo cargar la configuración de la app.\n'
            'Revise que el archivo app_config.json no tenga errores.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
