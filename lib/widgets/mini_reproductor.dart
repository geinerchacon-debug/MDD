import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../services/radio_service.dart';

/// Barra pequeña que aparece en las demás secciones mientras suena la radio.
class MiniReproductor extends StatelessWidget {
  final AppConfig config;
  final VoidCallback alTocar;
  const MiniReproductor({super.key, required this.config, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instancia;
    return ListenableBuilder(
      listenable: Listenable.merge(
          [radio.estado, radio.emisoraActual, radio.sonandoAhora]),
      builder: (context, _) {
        final emisora = radio.emisoraActual.value;
        if (emisora == null || !radio.activa) return const SizedBox.shrink();
        final cargando = radio.estado.value == EstadoRadio.cargando;
        final detalle = radio.sonandoAhora.value.isNotEmpty
            ? radio.sonandoAhora.value
            : (cargando ? 'Conectando…' : 'En vivo');
        return Material(
          color: config.colorTarjetas,
          child: InkWell(
            onTap: alTocar,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.graphic_eq, color: config.colorPrincipal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emisora.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(detalle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Detener',
                    icon: const Icon(Icons.stop_circle, size: 36),
                    color: config.colorPrincipal,
                    onPressed: radio.detener,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
