<!-- follows README.md sha256:unknown behind -->
# FactorIA

[English](README.md) | **Español**

> La versión en inglés es la referencia: si esta traducción difiere de ella, prevalece la versión en inglés.

> **Esta traducción va por detrás del texto inglés** ([README.md](README.md), al día en la versión 0.37; este texto sigue
> en la 0.1). Lo que falta aquí: el estado actual (versión 0.32 y los 11 juegos de ejemplo, no siete), el estado de la
> firma en «Descarga» (las descargas de Windows no están firmadas todavía), las licencias de terceros (además de MIT, zlib
> y dominio público hay Apache-2.0, BSL-1.0 y BSD-3-Clause) y la estructura del repositorio con `skills/` y el contenido
> actual de `scripts/` y `platforms/`. Lee el texto inglés para esos puntos; esta traducción no se ha puesto al día.
> La estructura (qué es, pruébalo, documentación por público) sí sigue a la inglesa.

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
`factoria`, el servidor MCP, la conexión con IAs y el editor. Además, siete juegos
de ejemplo hechos por agentes de IA solo con la interfaz pública forman parte de
los tests. Tres de ellos son juegos completos. Lantern Keep, un plataformas 2D de escritorio: menús, ranuras de partida,
servicios de tienda, opciones de accesibilidad, cuatro idiomas y ajustes listos para las tiendas. Clockwork Courier, un
juego 3D pensado primero para móviles: controles táctiles, modelos y sonidos CC0 importados, logros, compras y un anuncio
con recompensa, opciones de comodidad y accesibilidad, inglés, español y japonés, y exportaciones probadas en el
simulador de iOS, un emulador de Android, un navegador y macOS. Burrow Brigade, un juego 2D cooperativo para hasta cuatro
jugadores en una pantalla, para escritorio y Steam: minas generadas a partir de una semilla, enemigos que persiguen por
los túneles excavados, ranuras de partida con versión, clasificaciones y funciones online en servicios de prueba, inglés,
ruso y tailandés, y exportaciones a Windows, Linux y macOS.

La CI compila y prueba cada pull request y cada push a `main` en Linux, Windows
(MSVC) y macOS, y compila la app de iOS para el simulador y la librería y el APK de
Android, y los ejecuta en el simulador de iOS y en un emulador de Android (no en
dispositivos reales; véase [docs/MOBILE.md](docs/MOBILE.md), en inglés). Carencias abiertas y
próximos hitos: [feedback/ROADMAP.md](feedback/ROADMAP.md) (en inglés).

## Pruébalo

### Descarga

No hace falta compilador ni herramientas de desarrollo. Descarga una sola vez la última versión para tu sistema:
[instalador de Windows](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64-setup.exe)
(o el [zip](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64.zip)),
[macOS](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-macos-universal.tar.gz)
(Apple Silicon e Intel) o Linux ([tar.gz](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.tar.gz)
o [AppImage](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.AppImage)). Ejecuta el
instalador, o descomprime el zip / tar.gz en la carpeta que quieras, por ejemplo `C:\FactorIA` o `~/FactorIA`, y abre
el editor:

- **Windows:** menú Inicio > **FactorIA Editor** (instalador), o doble clic en `FactorIA-Editor.exe`. SmartScreen puede
  frenarlo (siempre con una versión sin firmar): pulsa **Más información > Ejecutar de todas formas**.
- **macOS:** ejecuta `./factoria editor` en Terminal desde la carpeta descomprimida. Las versiones posteriores a la
  0.1.3 están firmadas y notarizadas y se abren sin avisos. Gatekeeper bloquea la 0.1.3 y anteriores la primera vez:
  quita la cuarentena de descarga una vez, `xattr -dr com.apple.quarantine
  <carpeta>`, o permite `factoria` en Ajustes del Sistema > Privacidad y seguridad > **Abrir igualmente** (detalles en
  docs/GETTING_STARTED.md).
- **Linux:** ejecuta `./factoria editor` desde la carpeta descomprimida, o `./FactorIA-linux-x64.AppImage` (tras
  `chmod +x`; con argumentos es el comando `factoria`).

No hace falta volver a descargarlo: cuando sale una versión nueva, el editor muestra sus notas al abrirse y pregunta
si quieres actualizar. **Update** la instala en la misma carpeta y vuelve a abrir el editor; **Not now** mantiene tu
versión.

El asistente de IA necesita [Claude Code](https://claude.com/claude-code) instalado y con la sesión iniciada, o una
clave de API. Para usar Claude Code desde un terminal fuera del editor, añade la carpeta al PATH (el instalador de Windows lo hace); y la exportación a
Android e iOS sigue necesitando el código fuente del motor y los SDK de cada plataforma. Detalles:
[Descarga en GETTING_STARTED](docs/i18n/es/GETTING_STARTED.md#descarga-sin-compilar-nada).

### Tu primer juego

Abre el editor, crea un proyecto y pide un juego a la IA: [docs/FIRST_GAME_WITH_AI.md](docs/FIRST_GAME_WITH_AI.md) guía
a una persona paso a paso (en inglés) y [docs/MAKE_BY_HAND.md](docs/MAKE_BY_HAND.md) hace uno pequeño editando tú los
archivos, para ver qué hace la IA por ti. Desde un terminal: `factoria new mi-juego` y `factoria run mi-juego`
([docs/i18n/es/GETTING_STARTED.md](docs/i18n/es/GETTING_STARTED.md)).

### Compilar desde el código fuente (desarrollo del motor)

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

Requisitos por plataforma, presets y solución de problemas: [docs/design/BUILDING.md](docs/design/BUILDING.md).

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
docs/        documentación en inglés (va dentro del binario y las IAs la leen vía MCP); docs/design/ es para quien trabaja en el motor y no va en el binario; traducciones en docs/i18n/
scripts/     compilación y preparación del entorno en cada sistema operativo
templates/   plantillas de proyecto para `factoria new`
schemas/     esquemas JSON de proyecto, ENGINE_FEEDBACK y configuración de IA
examples/    juegos de ejemplo hechos por agentes de IA, también usados como pruebas de integración
feedback/    hoja de ruta construida a partir de los ENGINE_FEEDBACK.json de los ejemplos
platforms/   empaquetado para Android (Gradle) e iOS
```

## Documentación

Cada página de `docs/` y `docs/design/` está enlazada aquí (un test lo comprueba). La documentación de referencia está
en inglés; las de `docs/` van dentro del binario y una IA las lee con `factoria docs list` / `docs read` o las
herramientas `docs_*` de MCP; `docs/design/` es para quien trabaja en el motor y no va en el binario. Hay traducción al
español de esta página y de la guía de primeros pasos ([docs/i18n/es/GETTING_STARTED.md](docs/i18n/es/GETTING_STARTED.md)).

### Hacer un juego con una IA

- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md): instalar, crear un juego y conectar una IA (en inglés).
- [docs/FIRST_GAME_WITH_AI.md](docs/FIRST_GAME_WITH_AI.md): tutorial para personas: tu primer juego con una IA en el editor, paso a paso (en inglés).
- [docs/MAKE_BY_HAND.md](docs/MAKE_BY_HAND.md): tutorial: haz un juego pequeño a mano (escena, script, test, exportar) para entender qué hace la IA por ti (en inglés).
- [docs/AI_GUIDE.md](docs/AI_GUIDE.md): cómo crear un juego con FactorIA (para agentes de IA).
- [docs/SCRIPTING.md](docs/SCRIPTING.md): scripts de JavaScript: comportamientos, herramientas y tests.
- [docs/CLI.md](docs/CLI.md) y [docs/MCP.md](docs/MCP.md): la CLI `factoria` y el servidor MCP.
- [docs/reference/README.md](docs/reference/README.md): referencia de la API navegable, una página por categoría de componentes y de comandos (generada, en inglés).
- [docs/COMPONENTS.md](docs/COMPONENTS.md): todos los componentes y campos en un solo archivo (generado, 1,8 MB, no va en el binario: `docs.components` lo sirve por componente).
- [docs/DEBUGGING.md](docs/DEBUGGING.md): depurar scripts: puntos de interrupción en VS Code, `script.trace` para las IAs.
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): cómo las IAs registran lo que le falta al motor.
- [docs/SKILLS.md](docs/SKILLS.md): Agent Skills: guías por tema que una IA carga cuando el trabajo las necesita.
- [docs/HOOKS.md](docs/HOOKS.md): hooks: programas o módulos de JavaScript que se ejecutan antes y después de las llamadas de la IA y de los comandos del motor.
- [docs/EXTENDING.md](docs/EXTENDING.md): herramientas del proyecto, plugins nativos y (para quien trabaja en el motor) comandos, componentes y sistemas.

Temas, una página cada uno (en inglés):

- Arte 2D y 3D: [docs/ASSETS.md](docs/ASSETS.md), [docs/IMAGES.md](docs/IMAGES.md), [docs/VECTOR.md](docs/VECTOR.md), [docs/MODELING.md](docs/MODELING.md), [docs/RIGGING.md](docs/RIGGING.md), [docs/ANIMATION.md](docs/ANIMATION.md).
- Aspecto y sensación: [docs/PARTICLES.md](docs/PARTICLES.md), [docs/EFFECTS.md](docs/EFFECTS.md), [docs/GAME_FEEL.md](docs/GAME_FEEL.md), [docs/SHADERS.md](docs/SHADERS.md), [docs/RENDERING.md](docs/RENDERING.md), [docs/UPSCALING.md](docs/UPSCALING.md), [docs/LATENCY.md](docs/LATENCY.md), [docs/FRAME_GENERATION.md](docs/FRAME_GENERATION.md).
- Sonido: [docs/SOUND.md](docs/SOUND.md), [docs/MUSIC.md](docs/MUSIC.md).
- Texto y menús: [docs/TEXT.md](docs/TEXT.md), [docs/LOCALIZATION.md](docs/LOCALIZATION.md) (varios idiomas: tablas de textos, campos `key`, la API `i18n`), [docs/MENUS.md](docs/MENUS.md).
- Mundo y servicios: [docs/NAVIGATION.md](docs/NAVIGATION.md), [docs/BIG_WORLDS.md](docs/BIG_WORLDS.md) (páginas: [niveles de detalle y oclusión](docs/BIG_WORLDS_LOD.md), [streaming y origen flotante](docs/BIG_WORLDS_STREAMING.md), [terreno y follaje](docs/BIG_WORLDS_TERRAIN.md)), [docs/NETWORKING.md](docs/NETWORKING.md), [docs/PLATFORM.md](docs/PLATFORM.md), [docs/ANALYTICS.md](docs/ANALYTICS.md).

### Terminar y publicar un juego

- [docs/FINISHING.md](docs/FINISHING.md): termina tu juego: menús, opciones, partidas, idiomas, accesibilidad, servicios de tienda, créditos, tests y lista de comprobación (en inglés).
- [docs/PERFORMANCE.md](docs/PERFORMANCE.md): presupuestos de tiempo de fotograma, memoria y llamadas de dibujo (en inglés).
- [docs/EXPORTING.md](docs/EXPORTING.md) y [docs/MOBILE.md](docs/MOBILE.md): exportar juegos, e iOS/Android.
- [docs/PUBLISHING.md](docs/PUBLISHING.md): una lista de comprobación por tienda (Steam, Epic, GOG, Microsoft Store, Google Play, App Store, itch.io, web).
- [docs/LEGAL.md](docs/LEGAL.md): plantillas de política de privacidad y EULA para un juego publicado.

### Usar el editor

- [docs/EDITOR.md](docs/EDITOR.md): el editor visual, centrado en la IA (en inglés): vista del juego, chat con la IA, selección, registro de audio.
- [docs/AI_PROVIDERS.md](docs/AI_PROVIDERS.md): proveedores de IA (Claude Code, Codex, claves de API) y roles.
- [docs/AI_COSTS.md](docs/AI_COSTS.md): cuánto cuesta hacer un juego con IA y cómo gastar menos (en inglés).

### Desarrollo del motor

Lee primero [CLAUDE.md](CLAUDE.md) y [docs/design/ARCHITECTURE.md](docs/design/ARCHITECTURE.md). Estas páginas no van en el binario.

- [docs/design/ARCHITECTURE.md](docs/design/ARCHITECTURE.md): diseño, módulos, convenciones, comandos y reflexión (dividido en páginas: el archivo las enumera).
- [docs/design/BUILDING.md](docs/design/BUILDING.md): requisitos por plataforma, presets, CI, tests y solución de problemas (dividido en páginas: el archivo las enumera).
- [docs/design/CUSTOM_SHADERS.md](docs/design/CUSTOM_SHADERS.md), [docs/design/CUSTOM_SHADERS_KINDS.md](docs/design/CUSTOM_SHADERS_KINDS.md), [docs/design/CUSTOM_SHADERS_FULL.md](docs/design/CUSTOM_SHADERS_FULL.md), [docs/design/CUSTOM_SHADERS_PACKAGES.md](docs/design/CUSTOM_SHADERS_PACKAGES.md), [docs/design/FEEDBACK_SHARING.md](docs/design/FEEDBACK_SHARING.md) y [docs/design/SCRIPT_DEBUGGER.md](docs/design/SCRIPT_DEBUGGER.md): documentos de diseño (en inglés).
- [feedback/ROADMAP.md](feedback/ROADMAP.md) y [CHANGELOG.md](CHANGELOG.md).

## Licencia

FactorIA es código abierto bajo la [licencia MIT](LICENSE): puedes usarlo, modificarlo y publicar juegos con él,
gratuitos o comerciales, siempre que el aviso de copyright y la licencia acompañen al código del motor.

- **Tus juegos son tuyos.** Los archivos que `factoria new` pone en un proyecto son [MIT-0](templates/LICENSE) (no
  hace falta ningún aviso). Un juego exportado contiene el runtime de FactorIA, así que `factoria export` escribe
  `FACTORIA_NOTICES.txt` con las licencias del motor y del código de terceros que lleva dentro; inclúyelo en lo que
  distribuyas ([docs/EXPORTING.md](docs/exporting/EXPORTING_CONTENTS.md#license-notices), en inglés).
- **Código de terceros**: lo que hay en `external/` mantiene su propia licencia ([external/VERSIONS.md](external/VERSIONS.md);
  todas MIT, zlib o dominio público). `factoria docs licenses` muestra todos los avisos; las descargas los incluyen
  en `THIRD_PARTY_NOTICES.txt`.
- **El nombre.** La licencia cubre el código, no el nombre ni el logo de FactorIA. Puedes decir que tu juego está
  "hecho con FactorIA"; un motor modificado o redistribuido no debe presentarse como FactorIA, ni como respaldado por
  FactorIA, sin permiso.
- **Conducta.** Las issues, los pull requests, las discusiones y el servidor de feedback siguen el
  [código de conducta](CODE_OF_CONDUCT.md) (en inglés).
