# MDD Radio HD

App oficial de las emisoras de **Monte de Dios SJM** para Android y iPhone, hecha en Flutter.

## Qué hace
- Radio en vivo con sonido en segundo plano y controles en la pantalla bloqueada.
- Muestra la canción que suena (si la emisora la informa).
- Últimos videos del canal de YouTube (sin clave de API).
- Devocional, programación, peticiones de oración, donaciones, redes sociales, contacto y "Quiénes somos".
- Todo el menú y los textos se editan en `assets/config/app_config.json`, y la app puede leerlo desde internet sin publicar una nueva versión.

## Archivos importantes
| Archivo | Para qué sirve |
|---|---|
| `assets/config/app_config.json` | Menú, textos, colores y emisoras. **El que más va a editar.** |
| `lib/config/ajustes.dart` | Dirección de internet del archivo de configuración. |
| `assets/images/logo.png` | Logo que se ve dentro de la app. |
| `assets/images/icono_app.png` | Ícono de la app en el teléfono. |
| `pubspec.yaml` | Número de versión de la app. |
| `codemagic.yaml` | Instrucciones para compilar en la nube. |
| `tool/configurar_plataformas.py` | Ajustes automáticos de Android e iOS (no se edita). |

Las carpetas `android/` e `ios/` no se guardan en el repositorio: Codemagic las genera en cada compilación.

## Compilar en una computadora (opcional, para programadores)
```bash
flutter create --org cr.montededios --project-name mdd_radio --platforms=android,ios .
python3 tool/configurar_plataformas.py
flutter pub get
dart run flutter_launcher_icons
flutter run
```

Las instrucciones completas para editar y publicar están en el tutorial.
