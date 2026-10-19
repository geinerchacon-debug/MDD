import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/ajustes.dart';
import '../models/app_config.dart';

/// Carga la configuración (menú, textos, emisoras) en este orden:
/// 1. La última copia guardada en el teléfono (arranque instantáneo).
/// 2. Si no hay, la copia incluida dentro de la app.
/// 3. Luego, en segundo plano, descarga la versión de internet y la aplica.
class ConfigService {
  ConfigService._();
  static final ConfigService instancia = ConfigService._();

  static const _claveCache = 'config_cache_v1';

  final ValueNotifier<AppConfig?> config = ValueNotifier<AppConfig?>(null);

  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardada = prefs.getString(_claveCache);
    if (guardada != null) {
      config.value = _intentarLeer(guardada);
    }
    config.value ??=
        _intentarLeer(await rootBundle.loadString('assets/config/app_config.json'));
    unawaited(actualizarDesdeInternet());
  }

  /// Descarga la configuración remota. Devuelve true si se aplicó.
  Future<bool> actualizarDesdeInternet() async {
    const url = Ajustes.urlConfiguracionRemota;
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url).replace(queryParameters: {
        ...Uri.parse(url).queryParameters,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: Ajustes.tiempoEsperaSegundos));
      if (resp.statusCode != 200) return false;
      final cuerpo = utf8.decode(resp.bodyBytes);
      final nueva = _intentarLeer(cuerpo);
      if (nueva == null) return false; // archivo con errores: se ignora
      config.value = nueva;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveCache, cuerpo);
      return true;
    } catch (e) {
      debugPrint('No se pudo descargar la configuración: $e');
      return false;
    }
  }

  AppConfig? _intentarLeer(String texto) {
    try {
      final datos = jsonDecode(texto);
      if (datos is! Map) return null;
      return AppConfig.fromJson(Map<String, dynamic>.from(datos));
    } catch (e) {
      debugPrint('Configuración inválida: $e');
      return null;
    }
  }
}
