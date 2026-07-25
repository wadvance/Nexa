# AETHERIS

Assistente de inteligencia artificial manos libres con voz masculina en español, integración de clima, mapas, medicamentos (FDA) y más.

## Build para móvil (Android)

### Requisitos previos
- Flutter 3.24 o superior
- Android SDK
- Java 17
- Un dispositivo Android conectado o emulador

### Construir APK Debug

```bash
cd C:\NEXA
flutter pub get
flutter build apk --debug
```

El APK queda en: `build/app/outputs/flutter-apk/app-debug.apk`

### Instalar en dispositivo

```bash
flutter install
```

O copia el APK al móvil e instálalo manualmente.

## Build para Web

```bash
flutter build web
```

El bundle queda en `build/web/`.

## Ejecutar localmente

```bash
flutter run -d chrome   # Navegador
flutter run -d android # Móvil Android
flutter run -d ios     # iPhone (requiere macOS)
```

## Configuración (.env)

Tu archivo `.env` debe tener estas claves:

```
GEMINI_API_KEY=AIza...    # Recomendado: obtener en https://aistudio.google.com/app/apikey
OPENROUTER_API_KEY=sk-or-v1-...  # Opcional: respaldo en https://openrouter.ai/keys
GOOGLE_MAPS_API_KEY=AIza...     # Para navegación
OPENWEATHERMAP_API_KEY=...      # Para clima
```

> **Si no tienes Gemini API Key**: la app usará **OpenRouter** automáticamente (con modelo gratuito). Si tampoco la tienes, usará el **cerebro local** con conocimiento limitado (medicamentos, clima, etc.).

## Comandos de voz

- **Saludos**: "hola", "buenas tardes"
- **Clima**: "cómo está el clima", "qué temperatura hace", "llueve en David"
- **Navegación**: "ir a Madrid", "abre Google Maps en Nueva York"
- **Medicamentos**: "qué medicamento para dolor de cabeza", "para qué sirve el ibuprofeno"
- **Emergencia**: "activa protocolo de emergencia"
- **Más temas**: cualquier pregunta, la IA responderá.

## GitHub Actions

Cada push a `main` ejecuta:
1. Tests y análisis de código
2. Build del APK Android
3. Build para Web y deploy a GitHub Pages

Necesitas añadir estos **Secrets** en GitHub (`Settings → Secrets and variables → Actions`):

- `GEMINI_API_KEY`
- `OPENROUTER_API_KEY`  
- `GOOGLE_MAPS_API_KEY`
- `OPENWEATHERMAP_API_KEY`
