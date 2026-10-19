import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../services/radio_service.dart';

/// Sección "En vivo": reproductor grande y lista de emisoras.
class SeccionRadio extends StatelessWidget {
  final AppConfig config;
  const SeccionRadio({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instancia;
    if (config.emisoras.isEmpty) {
      return const Center(child: Text('Aún no hay emisoras configuradas.'));
    }
    return ListenableBuilder(
      listenable: Listenable.merge(
          [radio.emisoraActual, radio.estado, radio.sonandoAhora]),
      builder: (context, _) {
        final actualId = radio.emisoraActual.value?.id;
        final emisora = config.emisoras.firstWhere(
          (e) => e.id == actualId,
          orElse: () => config.emisoras.first,
        );
        final esLaActual = emisora.id == actualId;
        final estado = esLaActual ? radio.estado.value : EstadoRadio.detenida;
        final tema = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _Portada(emisora: emisora),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (estado == EstadoRadio.sonando)
              Center(child: _EtiquetaEnVivo(color: config.colorPrincipal)),
            const SizedBox(height: 8),
            Text(
              emisora.nombre,
              textAlign: TextAlign.center,
              style: tema.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (emisora.descripcion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                emisora.descripcion,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
            if (esLaActual && radio.sonandoAhora.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 18, color: config.colorPrincipal),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      radio.sonandoAhora.value,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            Center(
              child: _BotonPlay(
                estado: estado,
                color: config.colorPrincipal,
                alTocar: () => radio.alternar(emisora, nombreApp: config.nombre),
              ),
            ),
            if (estado == EstadoRadio.error) ...[
              const SizedBox(height: 16),
              Text(
                radio.mensajeError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (config.emisoras.length > 1) ...[
              const SizedBox(height: 32),
              Text('Nuestras emisoras', style: tema.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final e in config.emisoras)
                Card(
                  color: config.colorTarjetas,
                  child: ListTile(
                    leading: Icon(
                      e.id == actualId && radio.activa
                          ? Icons.graphic_eq
                          : Icons.radio,
                      color: config.colorPrincipal,
                    ),
                    title: Text(e.nombre),
                    subtitle: e.descripcion.isEmpty ? null : Text(e.descripcion),
                    onTap: () => radio.reproducir(e, nombreApp: config.nombre),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _Portada extends StatelessWidget {
  final Emisora emisora;
  const _Portada({required this.emisora});

  @override
  Widget build(BuildContext context) {
    const logo = Image(
      image: AssetImage('assets/images/logo.png'),
      fit: BoxFit.contain,
    );
    if (emisora.imagenUrl.isEmpty) {
      return const ColoredBox(color: Colors.black, child: logo);
    }
    return Image.network(
      emisora.imagenUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const ColoredBox(color: Colors.black, child: logo),
    );
  }
}

class _EtiquetaEnVivo extends StatelessWidget {
  final Color color;
  const _EtiquetaEnVivo({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: Colors.white),
          SizedBox(width: 6),
          Text('EN VIVO',
              style: TextStyle(
                  fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _BotonPlay extends StatelessWidget {
  final EstadoRadio estado;
  final Color color;
  final VoidCallback alTocar;

  const _BotonPlay({
    required this.estado,
    required this.color,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    switch (estado) {
      case EstadoRadio.cargando:
        contenido = const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        );
        break;
      case EstadoRadio.sonando:
        contenido = const Icon(Icons.stop, size: 52, color: Colors.white);
        break;
      case EstadoRadio.detenida:
      case EstadoRadio.error:
        contenido = const Icon(Icons.play_arrow, size: 56, color: Colors.white);
        break;
    }
    return Semantics(
      button: true,
      label: estado == EstadoRadio.sonando ? 'Detener radio' : 'Escuchar radio',
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: alTocar,
          child: SizedBox(
            width: 92,
            height: 92,
            child: Center(child: contenido),
          ),
        ),
      ),
    );
  }
}
