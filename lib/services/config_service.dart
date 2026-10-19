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
///
/// Cada paso falla por separado: si uno tiene problemas, se intenta el
/// siguiente, y los motivos quedan en [errores] para mostrarlos en pantalla.
class ConfigService {
  ConfigService._();
  static final ConfigService instancia = ConfigService._();

  static const _claveCache = 'config_cache_v1';
  static const _rutaIncluida = 'assets/config/app_config.json';

  final ValueNotifier<AppConfig?> config = ValueNotifier<AppConfig?>(null);

  /// Motivos por los que no se pudo leer alguna copia de la configuración.
  final ValueNotifier<List<String>> errores = ValueNotifier<List<String>>([]);

  void _anotarError(String origen, Object e) {
    final texto = '$origen: $e';
    debugPrint('Configuración — $texto');
    errores.value = [...errores.value, texto];
  }

  Future<void> iniciar() async {
    errores.value = [];

    // 1. Copia guardada en el teléfono.
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardada = prefs.getString(_claveCache);
      if (guardada != null) {
        config.value = _intentarLeer(guardada, 'Copia guardada');
      }
    } catch (e) {
      _anotarError('Copia guardada', e);
    }

    // 2. Copia incluida dentro de la app.
    if (config.value == null) {
      try {
        final texto = await rootBundle.loadString(_rutaIncluida);
        config.value = _intentarLeer(texto, 'Archivo incluido en la app');
      } catch (e) {
        _anotarError('Archivo incluido en la app', e);
      }
    }

    // 3. Versión de internet (si está configurada).
    unawaited(actualizarDesdeInternet());
  }

  /// Descarga la configuración remota. Devuelve true si se aplicó.
  Future<bool> actualizarDesdeInternet() async {
    const url = Ajustes.urlConfiguracionRemota;
    if (url.isEmpty) return false;
    try {
      final base = Uri.parse(url);
      final uri = base.replace(queryParameters: {
        ...base.queryParameters,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: Ajustes.tiempoEsperaSegundos));
      if (resp.statusCode != 200) {
        _anotarError('Archivo de internet', 'respuesta ${resp.statusCode}');
        return false;
      }
      final cuerpo = utf8.decode(resp.bodyBytes, allowMalformed: true);
      final nueva = _intentarLeer(cuerpo, 'Archivo de internet');
      if (nueva == null) return false; // archivo con errores: se ignora
      config.value = nueva;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_claveCache, cuerpo);
      } catch (e) {
        debugPrint('No se pudo guardar la copia: $e');
      }
      return true;
    } catch (e) {
      _anotarError('Archivo de internet', e);
      return false;
    }
  }

  AppConfig? _intentarLeer(String texto, String origen) {
    try {
      // Quita la marca invisible (BOM) que agregan algunos editores de Windows.
      final limpio = texto.startsWith('﻿') ? texto.substring(1) : texto;
      final datos = jsonDecode(limpio);
      if (datos is! Map) {
        throw const FormatException('el archivo no empieza con {');
      }
      return AppConfig.fromJson(Map<String, dynamic>.from(datos));
    } catch (e) {
      _anotarError(origen, e);
      return null;
    }
  }
}

