import 'package:flutter/material.dart';

import '../models/app_config.dart';

/// Sección de texto: devocional, quiénes somos, donaciones, etc.
class SeccionTexto extends StatelessWidget {
  final SeccionMenu seccion;
  final AppConfig config;
  const SeccionTexto({super.key, required this.seccion, required this.config});

  @override
  Widget build(BuildContext context) {
    if (seccion.bloques.isEmpty) {
      return const Center(child: Text('Próximamente.'));
    }
    final tema = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final b in seccion.bloques)
          Card(
            color: config.colorTarjetas,
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (b.imagenUrl.isNotEmpty)
                  Image.network(
                    b.imagenUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (b.titulo.isNotEmpty)
                        Text(b.titulo,
                            style: tema.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      if (b.subtitulo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(b.subtitulo,
                            style: tema.titleSmall?.copyWith(
                                color: config.colorPrincipal,
                                fontStyle: FontStyle.italic)),
                      ],
                      if (b.texto.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SelectableText(b.texto,
                            style: tema.bodyLarge?.copyWith(height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
