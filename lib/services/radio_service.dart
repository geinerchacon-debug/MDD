import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/app_config.dart';

enum EstadoRadio { detenida, cargando, sonando, error }

/// Maneja el reproductor de audio de toda la app (una sola emisora a la vez).
/// Gracias a just_audio_background el audio sigue sonando con la pantalla
/// bloqueada y aparecen los controles en la notificación / pantalla bloqueada.
class RadioService {
  RadioService._() {
    _player.playerStateStream.listen(_alCambiarEstado);
    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) {
      debugPrint('Error de transmisión: $e');
      _marcarError(
          'Se perdió la conexión con la emisora. Toque reproducir para intentar de nuevo.');
    });
    _player.icyMetadataStream.listen((meta) {
      sonandoAhora.value = meta?.info?.title?.trim() ?? '';
    });
  }

  static final RadioService instancia = RadioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _iniciando = false;

  final ValueNotifier<Emisora?> emisoraActual = ValueNotifier<Emisora?>(null);
  final ValueNotifier<EstadoRadio> estado =
      ValueNotifier<EstadoRadio>(EstadoRadio.detenida);

  /// Canción o programa que está sonando (si la emisora lo informa).
  final ValueNotifier<String> sonandoAhora = ValueNotifier<String>('');

  String mensajeError = '';

  bool get activa =>
      estado.value == EstadoRadio.sonando || estado.value == EstadoRadio.cargando;

  void _alCambiarEstado(PlayerState s) {
    if (estado.value == EstadoRadio.error && !_iniciando) return;
    if (!s.playing) {
      estado.value = _iniciando ? EstadoRadio.cargando : EstadoRadio.detenida;
      return;
    }
    switch (s.processingState) {
      case ProcessingState.idle:
      case ProcessingState.loading:
      case ProcessingState.buffering:
        estado.value = EstadoRadio.cargando;
        break;
      case ProcessingState.ready:
        estado.value = EstadoRadio.sonando;
        break;
      case ProcessingState.completed:
        estado.value = EstadoRadio.detenida;
        break;
    }
  }

  void _marcarError(String mensaje) {
    _iniciando = false;
    mensajeError = mensaje;
    estado.value = EstadoRadio.error;
  }

  Future<void> reproducir(Emisora emisora, {String nombreApp = ''}) async {
    emisoraActual.value = emisora;
    sonandoAhora.value = '';
    if (!emisora.disponible) {
      _marcarError('La transmisión de esta emisora estará disponible pronto.');
      return;
    }
    mensajeError = '';
    _iniciando = true;
    estado.value = EstadoRadio.cargando;
    try {
      final arte = Uri.tryParse(emisora.imagenUrl);
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(emisora.urlTransmision),
          tag: MediaItem(
            id: emisora.id,
            title: emisora.nombre,
            album: nombreApp.isEmpty ? 'En vivo' : nombreApp,
            artUri: (arte != null && arte.hasScheme) ? arte : null,
          ),
        ),
      );
      // play() termina solo cuando se detiene la radio; por eso no se espera.
      unawaited(_player.play());
      _iniciando = false;
    } catch (e) {
      debugPrint('Error al reproducir: $e');
      _marcarError(
          'No se pudo conectar con la emisora. Revise su conexión a internet e intente de nuevo.');
    }
  }

  /// En radio en vivo "detener" es mejor que "pausar": al volver a darle play
  /// se escucha lo que está sonando ahora y no lo de hace unos minutos.
  Future<void> detener() async {
    _iniciando = false;
    await _player.stop();
    estado.value = EstadoRadio.detenida;
  }

  Future<void> alternar(Emisora emisora, {String nombreApp = ''}) async {
    final misma = emisoraActual.value?.id == emisora.id;
    if (misma && activa) {
      await detener();
    } else {
      await reproducir(emisora, nombreApp: nombreApp);
    }
  }
}
