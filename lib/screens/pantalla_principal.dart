import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../sections/seccion_enlaces.dart';
import '../sections/seccion_programacion.dart';
import '../sections/seccion_radio.dart';
import '../sections/seccion_texto.dart';
import '../sections/seccion_video.dart';
import '../sections/seccion_youtube.dart';
import '../services/config_service.dart';
import '../utils/iconos.dart';
import '../widgets/mini_reproductor.dart';

/// Pantalla base: menú lateral, barra inferior y la sección seleccionada.
class PantallaPrincipal extends StatefulWidget {
  final AppConfig config;
  const PantallaPrincipal({super.key, required this.config});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _idSeleccionado;

  List<SeccionMenu> get _menu => widget.config.menuVisible;

  SeccionMenu? get _seccionActual {
    final menu = _menu.where((s) => s.tipo != TipoSeccion.web).toList();
    if (menu.isEmpty) return null;
    return menu.firstWhere(
      (s) => s.id == _idSeleccionado,
      orElse: () => menu.first,
    );
  }

  void _seleccionar(SeccionMenu seccion) {
    if (seccion.tipo == TipoSeccion.web) {
      abrirEnlace(context, seccion.url);
      return;
    }
    setState(() => _idSeleccionado = seccion.id);
  }

  void _irARadio() {
    final radio = _menu.where((s) => s.tipo == TipoSeccion.radio);
    if (radio.isNotEmpty) _seleccionar(radio.first);
  }

  Future<void> _actualizarContenido() async {
    Navigator.of(context).pop(); // cierra el menú
    final ok = await ConfigService.instancia.actualizarDesdeInternet();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Contenido actualizado.'
          : 'No hay contenido nuevo o no hay conexión.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final actual = _seccionActual;
    final barra =
        _menu.where((s) => s.barraInferior).take(4).toList(growable: false);
    final indiceBarra = actual == null
        ? barra.length
        : barra.indexWhere((s) => s.id == actual.id);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(actual?.titulo ?? config.nombre),
      ),
      drawer: _MenuLateral(
        config: config,
        seleccionado: actual?.id,
        alSeleccionar: (s) {
          Navigator.of(context).pop();
          _seleccionar(s);
        },
        alActualizar: _actualizarContenido,
      ),
      body: actual == null
          ? const Center(child: Text('No hay secciones visibles en el menú.'))
          : KeyedSubtree(
              key: ValueKey(actual.id),
              child: _construirSeccion(config, actual),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actual?.tipo != TipoSeccion.radio &&
              actual?.tipo != TipoSeccion.video)
            MiniReproductor(config: config, alTocar: _irARadio),
          if (barra.isNotEmpty)
            NavigationBar(
              backgroundColor: config.colorTarjetas,
              indicatorColor: config.colorPrincipal.withValues(alpha: 0.35),
              selectedIndex: indiceBarra < 0 ? barra.length : indiceBarra,
              onDestinationSelected: (i) {
                if (i >= barra.length) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  _seleccionar(barra[i]);
                }
              },
              destinations: [
                for (final s in barra)
                  NavigationDestination(icon: Icon(icono(s.icono)), label: s.titulo),
                const NavigationDestination(icon: Icon(Icons.menu), label: 'Más'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _construirSeccion(AppConfig config, SeccionMenu s) {
    switch (s.tipo) {
      case TipoSeccion.radio:
        return SeccionRadio(config: config);
      case TipoSeccion.video:
        return SeccionVideo(seccion: s, config: config);
      case TipoSeccion.youtube:
        return SeccionYoutube(seccion: s);
      case TipoSeccion.texto:
        return SeccionTexto(seccion: s, config: config);
      case TipoSeccion.programacion:
        return SeccionProgramacion(seccion: s, config: config);
      case TipoSeccion.enlaces:
        return SeccionEnlaces(seccion: s, config: config);
      case TipoSeccion.web:
      case TipoSeccion.desconocido:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Esta sección tiene un "tipo" que la app no reconoce.\n'
              'Revise el archivo de configuración.',
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}

class _MenuLateral extends StatelessWidget {
  final AppConfig config;
  final String? seleccionado;
  final ValueChanged<SeccionMenu> alSeleccionar;
  final VoidCallback alActualizar;

  const _MenuLateral({
    required this.config,
    required this.seleccionado,
    required this.alSeleccionar,
    required this.alActualizar,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: config.colorFondo,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Image.asset('assets/images/logo.png', height: 120),
            ),
            if (config.eslogan.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  config.eslogan,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            const Divider(),
            for (final s in config.menuVisible)
              ListTile(
                leading: Icon(icono(s.icono)),
                title: Text(s.titulo),
                trailing: s.tipo == TipoSeccion.web
                    ? const Icon(Icons.open_in_new, size: 18)
                    : null,
                selected: s.id == seleccionado,
                selectedColor: config.colorPrincipal,
                onTap: () => alSeleccionar(s),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Actualizar contenido'),
              onTap: alActualizar,
            ),
          ],
        ),
      ),
    );
  }
}
