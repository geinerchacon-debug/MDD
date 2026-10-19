import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../models/app_config.dart';
import '../services/radio_service.dart';
import '../utils/iconos.dart';

/// TV en vivo: muestra dentro de la app el reproductor web del proveedor
/// de video (por ejemplo el "hybrid player" de VDO Panel).
class SeccionVideo extends StatefulWidget {
  final SeccionMenu seccion;
  final AppConfig config;
  const SeccionVideo({super.key, required this.seccion, required this.config});

  @override
  State<SeccionVideo> createState() => _SeccionVideoState();
}

class _SeccionVideoState extends State<SeccionVideo> {
  WebViewController? _controller;
  bool _cargando = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.seccion.url);
    if (uri == null || !uri.hasScheme) {
      _error = true;
      _cargando = false;
      return;
    }

    // Para que no suenen la radio y el video al mismo tiempo.
    if (RadioService.instancia.activa) {
      RadioService.instancia.detener();
    }

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iPhone: reproducir dentro de la pantalla, no a pantalla completa forzada.
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _cargando = false);
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) {
            if (mounted) setState(() => _error = true);
          }
        },
      ))
      ..loadRequest(uri);

    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  void _reintentar() {
    final uri = Uri.tryParse(widget.seccion.url);
    if (_controller == null || uri == null) return;
    setState(() {
      _error = false;
      _cargando = true;
    });
    _controller!.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.seccion;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: _error || _controller == null
                  ? _Error(alReintentar: _reintentar)
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        WebViewWidget(controller: _controller!),
                        if (_cargando)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
            ),
          ),
        ),
        if (s.texto.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(s.texto,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.5)),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => abrirEnlace(context, s.url),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Ver en el navegador'),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final VoidCallback alReintentar;
  const _Error({required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white70),
          const SizedBox(height: 8),
          const Text('No se pudo cargar la transmisión.'),
          TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
