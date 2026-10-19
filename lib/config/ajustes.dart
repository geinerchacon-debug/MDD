/// Ajustes fijos de la app. Este es el ÚNICO archivo de código que
/// normalmente necesitará tocar (ver tutorial, capítulo 3).
class Ajustes {
  /// Dirección del archivo de configuración publicado en internet
  /// (por ejemplo, el enlace "Raw" de GitHub).
  ///
  /// Mientras esté vacío (''), la app usa la copia incluida en
  /// assets/config/app_config.json.
  static const String urlConfiguracionRemota = 'https://raw.githubusercontent.com/geinerchacon-debug/MDD/refs/heads/main/assets/config/app_config.json';

  /// Segundos máximos de espera al descargar la configuración.
  static const int tiempoEsperaSegundos = 8;
}
