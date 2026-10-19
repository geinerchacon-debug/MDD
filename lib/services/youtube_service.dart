import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class VideoYoutube {
  final String id;
  final String titulo;
  final DateTime? publicado;

  const VideoYoutube(this.id, this.titulo, this.publicado);

  String get miniatura => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  String get url => 'https://www.youtube.com/watch?v=$id';
}

/// Lee los últimos videos de un canal usando el feed RSS público de YouTube.
/// No requiere clave de API.
class YoutubeService {
  static Future<List<VideoYoutube>> ultimosVideos(String canalId) async {
    final uri = Uri.parse(
        'https://www.youtube.com/feeds/videos.xml?channel_id=$canalId');
    final resp = await http.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('YouTube respondió ${resp.statusCode}');
    }
    final doc = XmlDocument.parse(utf8.decode(resp.bodyBytes));
    final videos = <VideoYoutube>[];
    for (final entrada in _hijos(doc.rootElement, 'entry')) {
      final id = _primerTexto(entrada, 'videoId');
      if (id.isEmpty) continue;
      videos.add(VideoYoutube(
        id,
        _primerTexto(entrada, 'title'),
        DateTime.tryParse(_primerTexto(entrada, 'published')),
      ));
    }
    return videos;
  }

  /// Busca elementos por su nombre local (ignora prefijos como "yt:").
  static Iterable<XmlElement> _hijos(XmlElement padre, String nombre) =>
      padre.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == nombre);

  static String _primerTexto(XmlElement padre, String nombre) {
    final e = _hijos(padre, nombre);
    return e.isEmpty ? '' : e.first.innerText.trim();
  }
}
