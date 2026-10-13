# FactorIA

Motor de juegos 2D/3D en C++20 hecho para que las IAs creen juegos.

## Qué es

FactorIA está pensado para que un agente de IA (Claude, ChatGPT u otro) pueda crear,
probar y ajustar un juego sin depender de un editor gráfico:

- **Todo es texto.** Proyectos, escenas, prefabs y mapas de entrada son JSON con
  esquema. La lógica del juego se escribe en JavaScript, sin paso de compilación.
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

Desarrollo temprano. El repositorio ya tiene las dependencias integradas, la
compilación con CMake, la estructura de módulos y la documentación de arquitectura
y scripting. El primer hito está en curso: los módulos del motor y la CLI se están
implementando, así que muchos comandos todavía no funcionan.

La compilación se ha probado en Linux. Los flujos de macOS, Windows, iOS y Android
(presets, scripts y CI) están definidos, pero aún no se han ejecutado en esas
plataformas.

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

Comandos de la CLI (**en desarrollo**, aún no disponibles):

```bash
factoria new mi-juego                 # crea un proyecto a partir de una plantilla
cd mi-juego && factoria run           # ejecuta el juego
factoria mcp --project mi-juego       # servidor MCP: expone los comandos a agentes de IA
```

## Estructura del repositorio

```
engine/      módulos del motor: core, scene, platform, render, physics, audio, script, runtime
player/      factoria_player: runtime mínimo que llevan los juegos exportados
tools/       herramientas de desarrollo (desktop): CLI, servidor MCP, agente de IA, editor
cmake/       funciones de CMake y selección de plataforma
external/    dependencias de terceros integradas (no se editan)
docs/        documentación (se incluye en el binario y las IAs la leen vía MCP)
scripts/     compilación y preparación del entorno en cada sistema operativo
templates/   plantillas de proyecto para `factoria new` (en desarrollo)
schemas/     esquemas JSON de proyecto, ENGINE_FEEDBACK y configuración de IA (en desarrollo)
examples/    juegos de ejemplo, también usados como pruebas de integración (en desarrollo)
platforms/   empaquetado para Android (Gradle) e iOS (en desarrollo)
```

## Documentación

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): diseño, módulos, convenciones, comandos y reflexión.
- [docs/SCRIPTING.md](docs/SCRIPTING.md): scripts de JavaScript: comportamientos, herramientas y tests.
- [docs/BUILDING.md](docs/BUILDING.md): requisitos por plataforma, presets, tests y solución de problemas.
- [docs/AI_PROVIDERS.md](docs/AI_PROVIDERS.md): proveedores de IA (Claude Code, Codex, claves de API).
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): cómo las IAs registran lo que le falta al motor.

Si vas a modificar el motor, lee primero [CLAUDE.md](CLAUDE.md) y
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## English summary

FactorIA is a C++20 2D/3D game engine built so that AI agents can make games
reliably. Projects and scenes are JSON with schemas, gameplay is JavaScript
(QuickJS), and every engine capability is a command that is exposed as an MCP tool,
a CLI subcommand, an editor command and a script function. A headless mode gives
deterministic runs and screenshots. Agents connect through Claude Code, Codex or API
keys, and each game keeps an `ENGINE_FEEDBACK.json` that drives engine work.

Status: early development. The first milestone is in progress, and the CLI commands
above are not available yet. Build with `./scripts/build.sh debug --test` on Linux
and macOS, `scripts\build.ps1` on Windows, `scripts/build-ios.sh` for iOS and
`scripts/build-android.sh` for Android. See [docs/BUILDING.md](docs/BUILDING.md).
