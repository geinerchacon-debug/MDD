import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../services/youtube_service.dart';
import '../utils/iconos.dart';

/// Muestra los últimos videos del canal de YouTube configurado.
class SeccionYoutube extends StatefulWidget {
  final SeccionMenu seccion;
  const SeccionYoutube({super.key, required this.seccion});

  @override
  State<SeccionYoutube> createState() => _SeccionYoutubeState();
}

class _SeccionYoutubeState extends State<SeccionYoutube> {
  late Future<List<VideoYoutube>> _videos;

  @override
  void initState() {
    super.initState();
    _videos = _cargar();
  }

  Future<List<VideoYoutube>> _cargar() =>
      YoutubeService.ultimosVideos(widget.seccion.canalYoutube);

  Future<void> _recargar() async {
    final futuro = _cargar();
    setState(() => _videos = futuro);
    try {
      await futuro;
    } catch (_) {}
  }

  String _fecha(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(l.day)}/${dos(l.month)}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.seccion;
    if (s.canalYoutube.isEmpty) {
      return const Center(child: Text('Falta el código del canal de YouTube.'));
    }
    return RefreshIndicator(
      onRefresh: _recargar,
      child: FutureBuilder<List<VideoYoutube>>(
        future: _videos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || (snap.data?.isEmpty ?? true)) {
            return ListView(
              padding: const EdgeInsets.all(32),
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.wifi_off, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'No se pudieron cargar los videos.\nDeslice hacia abajo para intentar de nuevo.',
                  textAlign: TextAlign.center,
                ),
                if (s.urlCanal.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => abrirEnlace(context, s.urlCanal),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir el canal en YouTube'),
                    ),
                  ),
                ],
              ],
            );
          }
          final videos = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (s.urlCanal.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: () => abrirEnlace(context, s.urlCanal),
                    icon: const Icon(Icons.smart_display),
                    label: const Text('Ver el canal completo'),
                  ),
                ),
              for (final v in videos)
                Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => abrirEnlace(context, v.url),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                v.miniatura,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Colors.black),
                              ),
                              const Center(
                                child: Icon(Icons.play_circle_fill,
                                    size: 64, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (v.publicado != null) ...[
                                const SizedBox(height: 4),
                                Text(_fecha(v.publicado),
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 13)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
