import 'package:flutter/material.dart';

import '../models/app_config.dart';

/// Horario de programas de la radio, agrupado por día.
class SeccionProgramacion extends StatelessWidget {
  final SeccionMenu seccion;
  final AppConfig config;
  const SeccionProgramacion(
      {super.key, required this.seccion, required this.config});

  @override
  Widget build(BuildContext context) {
    if (seccion.dias.isEmpty) {
      return const Center(child: Text('Programación próximamente.'));
    }
    final tema = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final dia in seccion.dias) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(dia.dia.toUpperCase(),
                style: tema.titleSmall?.copyWith(
                    color: config.colorPrincipal,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1)),
          ),
          for (final p in dia.programas)
            Card(
              color: config.colorTarjetas,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(p.hora,
                          style: tema.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre,
                              style: tema.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          if (p.descripcion.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(p.descripcion,
                                style: tema.bodyMedium
                                    ?.copyWith(color: Colors.white70)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
