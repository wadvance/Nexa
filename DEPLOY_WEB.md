# Despliegue Web (GitHub Pages)

URL final: `https://wadvance.github.io/Nexa/`

## Pasos en GitHub

1. **Crear el repo** (si no existe): `wadvance/Nexa` (público para Pages gratis).
2. **Settings → Secrets and variables → Actions → New repository secret**:
   - `OPENROUTER_API_KEY` = tu clave `sk-or-…`
   - `OPENWEATHERMAP_API_KEY` = tu clave (si la usas)
3. **Settings → Pages**:
   - Source: **GitHub Actions** (no "Deploy from a branch").
4. **Push a `main`** → el workflow compila y publica.

## Archivos creados
- `.github/workflows/flutter-web-pages.yml` — build + deploy automático.

## Advertencias importantes
- **`flutter_dotenv` no es seguro en web**: la clave queda embebida en el JS compilado y será visible para cualquiera que abra DevTools. Es funcional, no seguro para producción. Cuando quieras protegerla, toca meter un proxy backend (Cloudflare Worker gratis).
- **`build/web/index.html` se copia a `404.html`** para que las rutas SPA (ej. `#/perfil`) sigan funcionando al recargar.
- Si más adelante cambias el nombre del repo, edita la línea:
  `--base-href /Nexa/` en el workflow y el `environment.url` si quieres.

## Primer push
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/wadvance/Nexa.git
git push -u origin main
```
