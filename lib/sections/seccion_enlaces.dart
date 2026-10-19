import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../utils/iconos.dart';

/// Lista de botones que abren enlaces: redes sociales, contacto, oración...
class SeccionEnlaces extends StatelessWidget {
  final SeccionMenu seccion;
  final AppConfig config;
  const SeccionEnlaces({super.key, required this.seccion, required this.config});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (seccion.texto.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
            child: Text(seccion.texto,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.5)),
          ),
        if (seccion.enlaces.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text('Próximamente.', textAlign: TextAlign.center),
          ),
        for (final e in seccion.enlaces)
          Card(
            color: config.colorTarjetas,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: config.colorPrincipal,
                foregroundColor: Colors.white,
                child: Icon(icono(e.icono)),
              ),
              title: Text(e.texto),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => abrirEnlace(context, e.url),
            ),
          ),
      ],
    );
  }
}
