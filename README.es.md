# FactorIA

[English](README.md) | **Español**

> La versión en inglés es la referencia: si esta traducción difiere de ella, prevalece la versión en inglés.

Motor de juegos 2D/3D en C++20 hecho para que las IAs creen juegos.

## Qué es

FactorIA está pensado para que un agente de IA (Claude, ChatGPT u otro) pueda crear,
probar y ajustar un juego sin depender de un editor gráfico:

- **Todo es texto.** Proyectos, escenas, prefabs y mapas de entrada son JSON con
  esquema. La lógica del juego se escribe en JavaScript (QuickJS), sin paso de compilación.
- **Las herramientas son comandos.** Cada capacidad del motor se registra una vez y
  queda disponible como herramienta MCP, comando de la CLI, comando del editor y
  función de JavaScript. La documentación va dentro del binario.
- **Modo headless.** Ejecución determinista sin ventana, con capturas de pantalla,
  volcados de estado en JSON y tests de JavaScript.
- **Cuentas de IA existentes.** Puedes usar tu suscripción de Claude o ChatGPT a
  través de sus CLIs oficiales (Claude Code y Codex), o claves de API. Las claves se
  guardan en la configuración del usuario, nunca en los proyectos.
- **El motor aprende de su uso.** Cada juego tiene un `ENGINE_FEEDBACK.json` donde la
  IA anota lo que le faltaba al motor y cómo lo resolvió. Las herramientas de
  desarrollo agregan esos archivos para decidir qué mejorar.

Se compila para Windows, macOS, Linux, iOS y Android desde un único código fuente.

## Estado

Versión 0.1, primer hito completado. Funcionan todos los módulos del motor, la CLI
`factoria`, el servidor MCP, la conexión con IAs y el editor. Además, cuatro juegos
de ejemplo hechos por agentes de IA solo con la interfaz pública forman parte de
los tests.

La CI compila y prueba cada pull request y cada push a `main` en Linux, Windows
(MSVC) y macOS, y compila la app de iOS para el simulador y la librería y el APK de
Android. iOS y Android todavía
no se ejecutan en dispositivos ni emuladores en la CI. Carencias abiertas y
próximos hitos: [feedback/ROADMAP.md](feedback/ROADMAP.md) (en inglés).

## Inicio rápido

Linux (Debian o Ubuntu) y macOS, desde la raíz del repositorio:

```bash
./scripts/bootstrap-linux.sh      # en macOS: ./scripts/bootstrap-macos.sh
./scripts/build.sh debug --test   # configura, compila y ejecuta los tests
```

Windows, en PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Test
```

iOS (simulador) y Android (arm64):

```bash
./scripts/build-ios.sh --simulator
./scripts/build-android.sh
```

Requisitos por plataforma, presets y solución de problemas: [docs/BUILDING.md](docs/BUILDING.md).

Después, crea y ejecuta un juego con la CLI `factoria` (se compila en `build/<preset>/tools/cli/`):

```bash
factoria new mi-juego --template 2d-platformer   # crea un proyecto a partir de una plantilla
factoria run mi-juego                             # ejecuta el juego en una ventana
factoria test mi-juego                            # ejecuta los tests JS del juego sin ventana
factoria mcp --project mi-juego                   # servidor MCP: expone los comandos a agentes de IA
```

Guía completa: [docs/i18n/es/GETTING_STARTED.md](docs/i18n/es/GETTING_STARTED.md).

## Estructura del repositorio

```
engine/      módulos del motor: core, scene, platform, render, physics, audio, script, runtime
player/      factoria_player: runtime mínimo que llevan los juegos exportados
tools/       herramientas de desarrollo (desktop): CLI, servidor MCP, agente de IA, editor
cmake/       funciones de CMake y selección de plataforma
external/    dependencias de terceros integradas (no se editan)
docs/        documentación en inglés (se incluye en el binario y las IAs la leen vía MCP); traducciones en docs/i18n/
scripts/     compilación y preparación del entorno en cada sistema operativo
templates/   plantillas de proyecto para `factoria new`
schemas/     esquemas JSON de proyecto, ENGINE_FEEDBACK y configuración de IA
examples/    juegos de ejemplo hechos por agentes de IA, también usados como pruebas de integración
feedback/    hoja de ruta construida a partir de los ENGINE_FEEDBACK.json de los ejemplos
platforms/   empaquetado para Android (Gradle) e iOS
```

## Documentación

La documentación de referencia está en inglés; hay traducción al español de esta
página y de la guía de primeros pasos.

- [docs/i18n/es/GETTING_STARTED.md](docs/i18n/es/GETTING_STARTED.md): compilar, crear un juego y conectar una IA (en español).
- [docs/AI_GUIDE.md](docs/AI_GUIDE.md): cómo crear un juego con FactorIA (para agentes de IA).
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): diseño, módulos, convenciones, comandos y reflexión.
- [docs/SCRIPTING.md](docs/SCRIPTING.md): scripts de JavaScript: comportamientos, herramientas y tests.
- [docs/COMPONENTS.md](docs/COMPONENTS.md): todos los componentes y campos (generado).
- [docs/EXTENDING.md](docs/EXTENDING.md): crear herramientas, comandos, componentes y sistemas.
- [docs/CLI.md](docs/CLI.md) y [docs/MCP.md](docs/MCP.md): la CLI `factoria` y el servidor MCP.
- [docs/EDITOR.md](docs/EDITOR.md): el editor visual, centrado en la IA (en inglés): vista del juego, chat con la IA, selección, registro de audio.
- [docs/AI_PROVIDERS.md](docs/AI_PROVIDERS.md): proveedores de IA (Claude Code, Codex, claves de API) y roles.
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): cómo las IAs registran lo que le falta al motor.
- [docs/BUILDING.md](docs/BUILDING.md): requisitos por plataforma, presets, CI, tests y solución de problemas.
- [docs/MOBILE.md](docs/MOBILE.md) y [docs/EXPORTING.md](docs/EXPORTING.md): iOS/Android y exportar juegos.

Si vas a modificar el motor, lee primero [CLAUDE.md](CLAUDE.md) y
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
