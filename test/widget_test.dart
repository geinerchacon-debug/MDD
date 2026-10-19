import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdd_radio/models/app_config.dart';

void main() {
  test('El archivo de configuración incluido se lee sin errores', () {
    final texto = File('assets/config/app_config.json').readAsStringSync();
    final config = AppConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(texto) as Map));
    expect(config.nombre, isNotEmpty);
    expect(config.emisoras, isNotEmpty);
    expect(config.menuVisible, isNotEmpty);
    expect(config.menu.where((s) => s.tipo == TipoSeccion.desconocido), isEmpty);
    expect(config.emisoras.first.disponible, isTrue);
    expect(config.menu.any((s) => s.tipo == TipoSeccion.video), isTrue);
  });

  test('Una emisora sin URL no se considera disponible', () {
    final e = Emisora.fromJson({'id': 'x', 'urlTransmision': 'PENDIENTE'});
    expect(e.disponible, isFalse);
  });
}
