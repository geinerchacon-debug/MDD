import 'package:flutter/material.dart';

/// Lectores tolerantes: si un campo falta o tiene otro tipo, se usa un valor
/// por defecto en lugar de cerrar la app.
String _texto(dynamic v, [String porDefecto = '']) =>
    v is String ? v.trim() : (v == null ? porDefecto : v.toString());

bool _bool(dynamic v, [bool porDefecto = true]) => v is bool ? v : porDefecto;

List<Map<String, dynamic>> _lista(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

Color colorDesdeHex(String hex, Color porDefecto) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final valor = int.tryParse(h, radix: 16);
  return (h.length == 8 && valor != null) ? Color(valor) : porDefecto;
}

class AppConfig {
  final String nombre;
  final String eslogan;
  final Color colorPrincipal;
  final Color colorFondo;
  final Color colorTarjetas;
  final List<Emisora> emisoras;
  final List<SeccionMenu> menu;

  const AppConfig({
    required this.nombre,
    required this.eslogan,
    required this.colorPrincipal,
    required this.colorFondo,
    required this.colorTarjetas,
    required this.emisoras,
    required this.menu,
  });

  /// Solo las secciones marcadas como visibles.
  List<SeccionMenu> get menuVisible => menu.where((s) => s.visible).toList();

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final app = json['app'] is Map
        ? Map<String, dynamic>.from(json['app'] as Map)
        : <String, dynamic>{};
    final menu = _lista(json['menu']).map(SeccionMenu.fromJson).toList();
    if (menu.isEmpty) {
      throw const FormatException('La configuración no tiene secciones en "menu".');
    }
    return AppConfig(
      nombre: _texto(app['nombre'], 'MDD Radio HD'),
      eslogan: _texto(app['eslogan']),
      colorPrincipal:
          colorDesdeHex(_texto(app['colorPrincipal']), const Color(0xFFE3121C)),
      colorFondo:
          colorDesdeHex(_texto(app['colorFondo']), const Color(0xFF0B0B0D)),
      colorTarjetas:
          colorDesdeHex(_texto(app['colorTarjetas']), const Color(0xFF1A1A1F)),
      emisoras: _lista(json['emisoras']).map(Emisora.fromJson).toList(),
      menu: menu,
    );
  }
}

class Emisora {
  final String id;
  final String nombre;
  final String descripcion;
  final String urlTransmision;
  final String imagenUrl;

  const Emisora({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlTransmision,
    required this.imagenUrl,
  });

  /// La emisora tiene una dirección de transmisión válida.
  bool get disponible {
    final uri = Uri.tryParse(urlTransmision);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  factory Emisora.fromJson(Map<String, dynamic> json) => Emisora(
        id: _texto(json['id'], 'emisora'),
        nombre: _texto(json['nombre'], 'Emisora'),
        descripcion: _texto(json['descripcion']),
        urlTransmision: _texto(json['urlTransmision']),
        imagenUrl: _texto(json['imagenUrl']),
      );
}

/// Tipos de sección que la app sabe mostrar.
enum TipoSeccion {
  radio,
  video,
  youtube,
  texto,
  programacion,
  enlaces,
  web,
  desconocido
}

TipoSeccion _tipo(String t) {
  switch (t.toLowerCase()) {
    case 'radio':
      return TipoSeccion.radio;
    case 'video':
    case 'tv':
      return TipoSeccion.video;
    case 'youtube':
      return TipoSeccion.youtube;
    case 'texto':
      return TipoSeccion.texto;
    case 'programacion':
    case 'programación':
      return TipoSeccion.programacion;
    case 'enlaces':
      return TipoSeccion.enlaces;
    case 'web':
      return TipoSeccion.web;
    default:
      return TipoSeccion.desconocido;
  }
}

class SeccionMenu {
  final String id;
  final String titulo;
  final String icono;
  final TipoSeccion tipo;
  final bool visible;
  final bool barraInferior;

  // Campos que solo usan algunos tipos de sección.
  final String texto; // enlaces, video
  final String canalYoutube; // youtube
  final String urlCanal; // youtube
  final String url; // web, video
  final List<BloqueTexto> bloques; // texto
  final List<DiaProgramacion> dias; // programacion
  final List<Enlace> enlaces; // enlaces

  const SeccionMenu({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.tipo,
    required this.visible,
    required this.barraInferior,
    required this.texto,
    required this.canalYoutube,
    required this.urlCanal,
    required this.url,
    required this.bloques,
    required this.dias,
    required this.enlaces,
  });

  factory SeccionMenu.fromJson(Map<String, dynamic> json) => SeccionMenu(
        id: _texto(json['id']),
        titulo: _texto(json['titulo'], 'Sección'),
        icono: _texto(json['icono'], 'info'),
        tipo: _tipo(_texto(json['tipo'])),
        visible: _bool(json['visible']),
        barraInferior: _bool(json['barraInferior'], false),
        texto: _texto(json['texto']),
        canalYoutube: _texto(json['canalYoutube']),
        urlCanal: _texto(json['urlCanal']),
        url: _texto(json['url']),
        bloques: _lista(json['bloques']).map(BloqueTexto.fromJson).toList(),
        dias: _lista(json['dias']).map(DiaProgramacion.fromJson).toList(),
        enlaces: _lista(json['enlaces'])
            .map(Enlace.fromJson)
            .where((e) => e.url.isNotEmpty)
            .toList(),
      );
}

class BloqueTexto {
  final String titulo;
  final String subtitulo;
  final String texto;
  final String imagenUrl;

  const BloqueTexto(this.titulo, this.subtitulo, this.texto, this.imagenUrl);

  factory BloqueTexto.fromJson(Map<String, dynamic> json) => BloqueTexto(
        _texto(json['titulo']),
        _texto(json['subtitulo']),
        _texto(json['texto']),
        _texto(json['imagenUrl']),
      );
}

class DiaProgramacion {
  final String dia;
  final List<Programa> programas;

  const DiaProgramacion(this.dia, this.programas);

  factory DiaProgramacion.fromJson(Map<String, dynamic> json) =>
      DiaProgramacion(
        _texto(json['dia']),
        _lista(json['programas']).map(Programa.fromJson).toList(),
      );
}

class Programa {
  final String hora;
  final String nombre;
  final String descripcion;

  const Programa(this.hora, this.nombre, this.descripcion);

  factory Programa.fromJson(Map<String, dynamic> json) => Programa(
        _texto(json['hora']),
        _texto(json['nombre']),
        _texto(json['descripcion']),
      );
}

class Enlace {
  final String texto;
  final String icono;
  final String url;

  const Enlace(this.texto, this.icono, this.url);

  factory Enlace.fromJson(Map<String, dynamic> json) => Enlace(
        _texto(json['texto']),
        _texto(json['icono'], 'web'),
        _texto(json['url']),
      );
}
