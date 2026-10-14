# Primeros pasos con FactorIA

[English](../../GETTING_STARTED.md) | **Español**

> La versión en inglés es la referencia: si esta traducción difiere de ella, prevalece la versión en inglés.

> AI agents: read [AI_GUIDE.md](../../AI_GUIDE.md) first, the complete English guide for building a game (also available as `factoria docs read ai-guide`).

FactorIA es un motor de juegos 2D y 3D en C++20 pensado para que una IA cree juegos sin depender de un editor gráfico. Las escenas son JSON, la lógica va en JavaScript y cada capacidad del motor es un comando que la IA puede invocar. Esta guía explica cómo compilar el motor, crear un juego y conectar una IA.

> **Estado del proyecto.** Está en desarrollo temprano. En Linux funciona el flujo completo: crear un proyecto, validarlo, probarlo, simularlo sin ventana con capturas, exportarlo y conectar una IA por MCP. La CI compila y prueba el motor en Windows (MSVC) y macOS (sin las pruebas de GPU), y compila la app del simulador de iOS, el player de Android y un APK de Android exportado en cada push; las builds móviles aún no se han ejecutado en un dispositivo (ver `docs/MOBILE.md`). La sección 8 resume lo que funciona y lo que falta.

## 1. Requisitos e instalación

Necesitas CMake 3.24 o superior y un compilador de C++20. En Linux y macOS los presets usan Ninja. Las librerías de terceros vienen incluidas en `external/`, así que no hay que descargar dependencias aparte, salvo los SDK de cada plataforma.

### Linux (Debian o Ubuntu)

```bash
./scripts/bootstrap-linux.sh      # instala compilador, CMake, Ninja y las librerías necesarias (se puede repetir)
./scripts/build.sh debug --test   # configura, compila y ejecuta los tests
```

El script funciona solo en sistemas con `apt` (Debian y Ubuntu) y usa `sudo` si no eres root. En otras distribuciones se detiene e imprime los paquetes equivalentes para Fedora y Arch; instala esos mismos componentes con tu gestor de paquetes y después ejecuta `./scripts/build.sh debug --test`.

### macOS

```bash
./scripts/bootstrap-macos.sh
./scripts/build.sh debug --test
```

Necesitas las herramientas de línea de comandos de Xcode (`xcode-select --install`). Para iOS hace falta Xcode completo.

### Windows

1. Instala Visual Studio 2022 con la carga de trabajo «Desarrollo para escritorio con C++» (en inglés, *Desktop development with C++*). Community sirve.
2. Desde la raíz del repositorio, en PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Test
```

Para compilar con Ninja (`windows-ninja-debug`), instala Ninja y ejecuta el script desde «Developer PowerShell for VS 2022», que pone `cl.exe` en el PATH:

```powershell
winget install Ninja-build.Ninja
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Preset windows-ninja-debug -Test
```

### iOS y Android

```bash
./scripts/build-ios.sh --simulator    # iOS Simulator; requiere Xcode completo
./scripts/build-android.sh            # Android arm64; requiere el NDK r26 o superior y ANDROID_NDK_HOME
```

### Presets

Cada compilación va a `build/<preset>/`. Para ver los presets que funcionan en tu equipo, ejecuta `cmake --list-presets`.

| Preset | Sistema | Uso |
|---|---|---|
| `linux-debug`, `linux-release` | Linux | Desarrollo y publicación |
| `macos-debug`, `macos-release` | macOS | Desarrollo y publicación |
| `windows-debug`, `windows-release` | Windows (Visual Studio 2022) | Desarrollo y publicación |
| `windows-ninja-debug` | Windows (Ninja con `cl`) | Desde Developer PowerShell |
| `ios`, `ios-simulator` | macOS con Xcode | Dispositivo y simulador |
| `android-arm64`, `android-x86_64` | Cualquier equipo con el NDK | Dispositivo y emulador |

Para compilar sin los scripts:

```bash
cmake --preset linux-debug
cmake --build --preset linux-debug
ctest --preset linux-debug
```

Si el equipo se queda sin memoria, limita los procesos: `cmake --build --preset linux-debug -- -j 2`.

### Problemas frecuentes

- **`Could not use disabled preset`**: el preset es de otro sistema operativo. Usa `cmake --list-presets`.
- **`Does not match the generator used previously: Ninja`**: borra `build/<preset>` y vuelve a configurar.
- **CMake demasiado antiguo**: instala CMake 3.24 o superior desde cmake.org.
- **`Could NOT find X11` u `OpenGL` (Linux)**: ejecuta `./scripts/bootstrap-linux.sh`.
- **Los tests headless fallan sin pantalla (Linux)**: ejecútalos con un servidor virtual: `xvfb-run -a -s "-screen 0 1280x720x24" ctest --preset linux-debug`.
- **`cl.exe not found`**: usa «Developer PowerShell for VS 2022».
- **`running scripts is disabled on this system`**: ejecuta el script con `-ExecutionPolicy Bypass`.

Más detalles en `docs/BUILDING.md`.

## 2. Crear tu primer juego

Con la CLI `factoria` crearás un proyecto a partir de una plantilla:

```bash
factoria new mi-juego --template 2d-platformer
cd mi-juego
```

Plantillas disponibles:

- `2d-empty`: un cuadrado controlable con WASD o las flechas. No usa recursos gráficos.
- `2d-platformer`: plataformas con física, monedas, marcador y una cámara que sigue al jugador.
- `3d-empty`: una cámara de vuelo, una luz, un suelo y un cubo que gira.

`factoria templates` muestra las plantillas disponibles con su descripción.

El proyecto contiene:

- `factoria.json`: ajustes de pantalla, física y controles.
- `scenes/`: niveles en JSON.
- `scripts/`: comportamientos en JavaScript.
- `tools/`: herramientas de proyecto que la IA puede invocar.
- `tests/`: pruebas headless.
- `types/factoria.d.ts`: tipos de la API de scripts, generados por el motor.
- `AGENTS.md`: guía corta para la IA.
- `ENGINE_FEEDBACK.json`: lo que le faltó al motor (sección 7).
- `.mcp.json`: conexión con Claude Code.
- `jsconfig.json`: comprobación de tipos para el JavaScript.

## 3. Ejecutar el juego

```bash
factoria run
```

Se abre una ventana con el juego. Los controles están definidos en `factoria.json`, dentro de `input.actions`:

- `2d-empty`: A, D, W y S o las flechas.
- `2d-platformer`: A y D o las flechas para moverte; Espacio, W o la flecha arriba para saltar.
- `3d-empty`: W y S o las flechas para avanzar y retroceder; A y D para moverte de lado; E o Espacio para subir; Q o LeftShift para bajar.

## 4. Modo sin ventana y capturas

Sin ventana, el juego avanza sin abrir ninguna ventana. Solo dibuja las capturas que pides y el último fotograma, así que es rápido. El resultado es determinista: con la misma semilla y las mismas entradas se obtienen los mismos fotogramas.

```bash
factoria run --headless --frames 120 --screenshot-at 119
```

- Simula 120 fotogramas, es decir, 2 segundos de juego a 60 por segundo.
- Guarda una captura en `.factoria/screenshots/`, por defecto `frame_119.png`. Ábrela y comprueba que muestra lo que esperabas.
- Los fotogramas empiezan en 0 y la captura del fotograma N se toma después de simularlo. Por eso, con 120 fotogramas, la captura es la 119.
- `--state-out out.json` guarda el estado del mundo en JSON: entidades, componentes, registros y errores.
- `--record-audio out.wav` guarda el sonido mezclado, para comprobar que el juego suena.
- `--input replay.json` aplica una secuencia de pulsaciones fotograma a fotograma (acciones, teclas, ratón, mando y toques), por ejemplo `{"frames": {"0": {"press": ["jump"]}, "30": {"release": ["jump"]}}}`.
- Para una sola captura, `factoria screenshot --frames 120 --out shot.png` simula los fotogramas indicados y guarda la imagen.
- `--json` imprime el informe en JSON, con las rutas de las capturas.

## 5. Validación y tests

```bash
factoria validate    # comprueba el proyecto: JSON, escenas, recursos, controles y scripts
factoria test        # ejecuta tests/*.test.js sin ventana
```

`factoria validate --fix-types` regenera `types/factoria.d.ts` a partir de la API del motor.

Un test de la plantilla `2d-empty` tiene este aspecto:

```js
import { test, expect, game } from "factoria:test";

test("player moves right while move_right is held", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30); // 0.5 s at 60 Hz
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});
```

Cada archivo de test se ejecuta en un motor nuevo y con la semilla del proyecto, así que los resultados son reproducibles.

## 6. Conectar una IA

Hay dos formas de trabajar con una IA dentro de FactorIA. Puedes combinarlas.

| | Suscripción con la CLI oficial | Clave de API |
|---|---|---|
| Qué usas | Claude Code (Claude) o Codex (ChatGPT) | La IA integrada de `factoria ai` (Anthropic u otros proveedores) |
| Quién ejecuta el bucle del agente | La propia CLI | FactorIA |
| Qué pagas | Tu plan actual de Claude o ChatGPT | Tokens, al proveedor |
| Dónde están las credenciales | En la CLI, con tu inicio de sesión | En una variable de entorno o en `~/.factoria/ai.json` |

FactorIA nunca lee, guarda ni reenvía las credenciales de tu suscripción. Solo arranca la CLI oficial que tú instalas y le conecta su servidor MCP.

### Opción A: Claude Code o Codex con tu suscripción (MCP)

**Claude Code**

1. Instala la CLI e inicia sesión una vez:

```bash
npm i -g @anthropic-ai/claude-code
claude
```

2. `factoria new` crea en el proyecto un archivo `.mcp.json` con esta configuración:

```json
{ "mcpServers": { "factoria": { "command": "factoria", "args": ["mcp", "--project", "."] } } }
```

Si tu proyecto no tiene `.mcp.json`, el mismo servidor se añade con:

```bash
claude mcp add factoria -- factoria mcp --project .
```

3. Abre `claude` dentro de la carpeta del juego. La primera vez, es posible que te pida aprobar el servidor `factoria`.
4. Pide el trabajo en lenguaje natural, por ejemplo: "Lee AGENTS.md y añade un enemigo que persiga al jugador."

**Codex**

1. Instala la CLI e inicia sesión con tu cuenta de ChatGPT:

```bash
npm i -g @openai/codex
codex login
```

2. Añade el servidor a `~/.codex/config.toml`:

```toml
[mcp_servers.factoria]
command = "factoria"
args = ["mcp", "--project", "/ruta/a/mi-juego"]
```

El servidor MCP expone cada comando como herramienta, la documentación como recursos `factoria://docs/...` y las capturas de pantalla como imágenes. Incluye también los prompts `make-game`, `add-feature`, `fix-bug` y `report-engine-gap`, que guían a la IA paso a paso. Normalmente el cliente lo arranca por ti. Para depurarlo, puedes arrancarlo a mano con `factoria mcp --project mi-juego`.

### Opción B: IA integrada con clave de API

`factoria ai doctor` y `factoria ai providers` no necesitan clave: muestran qué proveedores están listos en tu equipo.

1. Guarda tu clave en una variable de entorno. Nunca la pongas dentro de un proyecto:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

Si tienes instalada la CLI `ant` y has iniciado sesión con `ant auth login`, FactorIA también puede usarla.

2. Opcional: crea `~/.factoria/ai.json` para fijar los límites de cada ejecución. En Windows, la ruta es `%APPDATA%\factoria\ai.json`:

```json
{
  "limits": { "maxTurns": 40, "maxCostUsd": 5 }
}
```

Sin este archivo se usan los valores por defecto de Anthropic.

3. Comprueba qué está disponible. El comando muestra las CLI y las claves que encuentra, sin imprimir ninguna clave:

```bash
factoria ai doctor
```

4. Pide una tarea:

```bash
factoria ai run "Añade un marcador de monedas en pantalla"
```

Cada tarea usa un rol. En `~/.factoria/ai.json` puedes asignar un proveedor y un modelo a cada uno:

| Rol (clave en el archivo) | Para qué sirve | Valor por defecto (Anthropic) |
|---|---|---|
| Orquestador (`orchestrator`) | Planifica, revisa y delega | `claude-opus-5-5`, esfuerzo `xhigh` |
| Trabajador (`worker`) | Implementa funciones y arreglos | `claude-sonnet-5-5`, esfuerzo `medium` |
| Rápido (`fast`) | Cambios mecánicos y pequeños | `claude-haiku-5-5`, esfuerzo `max` |

`factoria ai run` usa el rol orquestador, salvo que indiques otro con `--role orchestrator|worker|fast`. También puedes elegir proveedor y modelo con `--provider` y `--model`, y limitar la ejecución con `--max-turns` y `--max-cost` (en dólares).

Los límites `maxTurns` (número de pasos) y `maxCostUsd` (coste máximo en dólares) detienen una ejecución cuando se alcanzan. Las cifras de coste son estimaciones: manda la factura del proveedor.

FactorIA solo lee claves de variables de entorno o de `~/.factoria/ai.json`. Si encuentra algo que parece una clave dentro de un proyecto, avisa. Para usar un modelo local, como Ollama o LM Studio, configura un proveedor compatible con OpenAI (ver `docs/AI_PROVIDERS.md`). Así el contenido no sale de tu equipo.

## 7. ENGINE_FEEDBACK.json en palabras sencillas

Cada juego tiene un archivo `ENGINE_FEEDBACK.json` en su raíz. En él, la IA anota lo que le faltó al motor (una función, un comando o un dato de la documentación) y cómo lo resolvió.

- **Para qué sirve.** El equipo de FactorIA junta estos archivos de muchos juegos. Lo que aparece una y otra vez sube en la lista de lo que hay que construir. Así el motor mejora con el uso real.
- **Qué hace la IA.** En cuanto le falta algo, llama a la herramienta `feedback_report` (MCP). Sin MCP, usa `factoria feedback add` o edita el archivo a mano. Si el mismo hueco aparece otra vez, no se duplica la entrada: se suma un caso.
- **Qué tienes que hacer tú.** Nada. Puedes leerlo cuando quieras. Es texto normal y puedes editarlo o borrar entradas.
- **Privacidad.** El archivo no se envía a ningún sitio por sí solo. Cuando usas la IA integrada con una API, los títulos de estas entradas forman parte de lo que se envía al proveedor (ver `docs/AI_PROVIDERS.md`).

Ejemplo de entrada:

```json
{
  "category": "input",
  "severity": "minor",
  "title": "No gamepad rumble",
  "missing": "The game wants to vibrate the controller when the player is hit, but scripts have no rumble API.",
  "workaround": "none: feature dropped. A hit is shown with a screen shake only.",
  "workaroundFiles": [],
  "suggestion": "Add input.gamepad(i).rumble(strong, weak, seconds) that vibrates the pad.",
  "effort": "small"
}
```

Qué significa cada campo:

- `category`: el área del motor afectada, por ejemplo `physics`, `audio` o `scene`.
- `severity`: `blocker` (no se pudo construir), `major` (una solución grande o frágil), `minor` (una solución pequeña) o `nice-to-have` (sería más cómodo).
- `title`: un nombre corto del hueco. Usa siempre las mismas palabras para el mismo hueco.
- `missing`: qué faltaba.
- `workaround`: cómo se resolvió y en qué archivos.
- `suggestion`: qué debería hacer el motor.

Las claves y los valores fijos (`category`, `severity`) van en inglés, como en el ejemplo. El texto libre puede escribirse en el idioma que quieras. `factoria validate` falla si el archivo falta o no cumple el esquema `schemas/engine-feedback.schema.json`.

## 8. Qué funciona y qué falta

| Parte | Estado |
|---|---|
| Compilación en Linux (`./scripts/build.sh`) | Probada |
| Compilación en Windows, macOS, iOS y Android | La CI compila en cada push. Windows (MSVC) y macOS ejecutan los tests (macOS sin las pruebas de GPU); simulador de iOS y Android solo se compilan, sin ejecutar aún en un dispositivo (`docs/MOBILE.md`) |
| Motor: escenas, scripts de JavaScript, render 2D y 3D, física (incluidas plataformas de un sentido y tilemaps), partículas y capturas | Funciona en Linux. El audio no se ha probado en el entorno de documentación |
| CLI `factoria`: `new`, `templates`, `run`, `screenshot`, `test`, `validate`, `call`, `session`, `commands`, `api`, `mcp`, `ai`, `feedback`, `docs`, `export` | Funciona en Linux |
| `factoria editor` (editor visual) | Incluido en las builds de escritorio (`docs/EDITOR.md`, en inglés). Necesita pantalla. En Linux las pruebas `editor_autotest` de ctest lo ejercitan de punta a punta con `xvfb-run` |
| Plantillas de proyecto (`factoria new`): `2d-empty`, `2d-platformer`, `3d-empty` | Funciona |
| Servidor MCP para Claude Code y Codex (`factoria mcp`) | Funciona |
| IA integrada con clave de API (`factoria ai`) | `doctor`, `providers` y `config` funcionan. `ai run` necesita una clave de API o una CLI instalada (Claude Code o Codex) |
| Exportar juegos (`factoria export`) | Linux probado (`--platform linux`); la CI exporta un juego de Android y compila su APK. Windows, macOS, Android e iOS: ver `docs/EXPORTING.md` y `docs/MOBILE.md` |
| Documentación para IA | En inglés: `docs/AI_GUIDE.md`, `factoria docs read ai-guide` |
| Mandos (gamepad) | Bindings (`GamepadA`, `GamepadLeftStickLeft`, ...), `input.gamepad(i)` y `game.gamepad(i)` en los tests. Mandos reales: Windows (XInput), Linux (API joystick) y macOS/iOS (GameController) están escritos pero sin probar; Android y web aún no tienen soporte (`docs/MOBILE.md`) |

## 9. Dónde seguir leyendo

- `factoria help <comando>` muestra la ayuda y ejemplos de cada comando. `docs/CLI.md` describe todos los comandos y opciones.
- `docs/AI_GUIDE.md` (en inglés): la guía completa para una IA que construye un juego. Si eres una IA, léela antes de tocar un juego. Está disponible también con `factoria docs read ai-guide`.
- `docs/ARCHITECTURE.md`: diseño, módulos y convenciones.
- `docs/SCRIPTING.md`: la API de JavaScript: comportamientos, herramientas y tests.
- `docs/EXTENDING.md`: cómo añadir herramientas de proyecto y comandos del motor.
- `docs/MCP.md`, `docs/AI_PROVIDERS.md` y `docs/ENGINE_FEEDBACK.md`: conexión con IA y registro de lo que le falta al motor.
- `docs/BUILDING.md`: requisitos y compilación por plataforma.
- `docs/EXPORTING.md` y `docs/MOBILE.md`: exportar juegos y compilarlos para móvil.
