#!/usr/bin/env python3
"""Prepara las carpetas android/ e ios/ que genera `flutter create`.

Agrega lo que la radio necesita para sonar en segundo plano, abrir enlaces
y mostrar el nombre de la app. Se puede ejecutar varias veces sin dañar nada.
Codemagic lo ejecuta automáticamente antes de compilar (ver codemagic.yaml).
"""
import json
import pathlib
import plistlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
config = json.loads((RAIZ / "assets/config/app_config.json").read_text(encoding="utf-8"))
NOMBRE = config.get("app", {}).get("nombre", "MDD Radio HD")


def android():
    ruta = RAIZ / "android/app/src/main/AndroidManifest.xml"
    if not ruta.exists():
        print("No existe android/: ejecute primero flutter create"); return
    xml = ruta.read_text(encoding="utf-8")

    if "xmlns:tools" not in xml:
        xml = xml.replace(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android"',
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    xmlns:tools="http://schemas.android.com/tools"', 1)

    permisos = ["INTERNET", "WAKE_LOCK", "FOREGROUND_SERVICE",
                "FOREGROUND_SERVICE_MEDIA_PLAYBACK", "POST_NOTIFICATIONS"]
    nuevos = "".join(
        f'    <uses-permission android:name="android.permission.{p}"/>\n'
        for p in permisos if f"android.permission.{p}\"" not in xml)
    if nuevos:
        xml = xml.replace("    <application", nuevos + "    <application", 1)

    xml = re.sub(r'android:label="[^"]*"', f'android:label="{NOMBRE}"', xml, count=1)
    if "usesCleartextTraffic" not in xml:
        xml = xml.replace('android:name="${applicationName}"',
                          'android:name="${applicationName}"\n'
                          '        android:usesCleartextTraffic="true"', 1)
    xml = xml.replace('android:name=".MainActivity"',
                      'android:name="com.ryanheise.audioservice.AudioServiceActivity"')

    if "com.ryanheise.audioservice.AudioService\"" not in xml:
        servicio = '''        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
'''
        xml = xml.replace("    </application>", servicio + "    </application>", 1)

    if "android.intent.action.DIAL" not in xml:
        consultas = '''        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
'''
        if "<queries>" in xml:
            xml = xml.replace("<queries>\n", "<queries>\n" + consultas, 1)
        else:
            xml = xml.replace("</manifest>",
                              "    <queries>\n" + consultas + "    </queries>\n</manifest>", 1)

    ruta.write_text(xml, encoding="utf-8")
    print("Android listo:", ruta)
    firma_android()


def firma_android():
    """Usa la llave de Google Play que Codemagic entrega en variables CM_*.
    Si no existen (compilación de prueba), se firma con la llave de depuración."""
    ruta = RAIZ / "android/app/build.gradle.kts"
    if not ruta.exists():
        print("Aviso: no se encontró build.gradle.kts; se omite la firma."); return
    g = ruta.read_text(encoding="utf-8")
    if "CM_KEYSTORE_PATH" in g:
        return
    bloque = '''    signingConfigs {
        create("release") {
            val llave = System.getenv("CM_KEYSTORE_PATH")
            if (llave != null) {
                storeFile = file(llave)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            }
        }
    }

    buildTypes {'''
    g = g.replace("    buildTypes {", bloque, 1)
    g = g.replace(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = if (System.getenv("CM_KEYSTORE_PATH") != null) '
        'signingConfigs.getByName("release") else signingConfigs.getByName("debug")', 1)
    ruta.write_text(g, encoding="utf-8")
    print("Firma Android lista:", ruta)


def ios():
    ruta = RAIZ / "ios/Runner/Info.plist"
    if not ruta.exists():
        print("No existe ios/: ejecute primero flutter create"); return
    with open(ruta, "rb") as f:
        plist = plistlib.load(f)
    plist["CFBundleDisplayName"] = NOMBRE
    plist["CFBundleName"] = NOMBRE[:15]
    modos = plist.setdefault("UIBackgroundModes", [])
    if "audio" not in modos:
        modos.append("audio")
    plist.setdefault("NSAppTransportSecurity", {})["NSAllowsArbitraryLoads"] = True
    esquemas = plist.setdefault("LSApplicationQueriesSchemes", [])
    for e in ["https", "http", "tel", "mailto", "whatsapp", "youtube"]:
        if e not in esquemas:
            esquemas.append(e)
    plist["ITSAppUsesNonExemptEncryption"] = False
    with open(ruta, "wb") as f:
        plistlib.dump(plist, f)
    print("iOS listo:", ruta)


if __name__ == "__main__":
    android()
    ios()
    sys.exit(0)
