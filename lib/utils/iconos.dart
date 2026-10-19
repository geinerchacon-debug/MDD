import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Nombres de íconos que se pueden usar en el archivo de configuración.
/// Para agregar uno nuevo: busque el ícono en https://fonts.google.com/icons
/// y añádalo a esta lista (ver tutorial, anexo B).
const Map<String, IconData> iconosDisponibles = {
  'radio': Icons.radio,
  'microfono': Icons.mic,
  'musica': Icons.music_note,
  'video': Icons.smart_display,
  'youtube': Icons.smart_display,
  'biblia': Icons.menu_book,
  'libro': Icons.menu_book,
  'calendario': Icons.calendar_month,
  'reloj': Icons.schedule,
  'oracion': Icons.volunteer_activism,
  'corazon': Icons.favorite,
  'donar': Icons.card_giftcard,
  'iglesia': Icons.church,
  'personas': Icons.groups,
  'noticias': Icons.newspaper,
  'evento': Icons.event,
  'telefono': Icons.phone,
  'whatsapp': Icons.chat,
  'mensaje': Icons.chat_bubble,
  'correo': Icons.email,
  'facebook': Icons.facebook,
  'instagram': Icons.photo_camera,
  'web': Icons.language,
  'ubicacion': Icons.place,
  'compartir': Icons.share,
  'estrella': Icons.star,
  'info': Icons.info,
};

IconData icono(String nombre) =>
    iconosDisponibles[nombre.toLowerCase().trim()] ?? Icons.circle;

/// Abre un enlace (web, teléfono, correo, WhatsApp...) fuera de la app.
Future<void> abrirEnlace(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  var abierto = false;
  if (uri != null && uri.hasScheme) {
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      abierto = false;
    }
  }
  if (!abierto && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el enlace.')),
    );
  }
}
