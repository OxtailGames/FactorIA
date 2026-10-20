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
`factoria`, el servidor MCP, la conexión con IAs y el editor. Además, cinco juegos
de ejemplo hechos por agentes de IA solo con la interfaz pública forman parte de
los tests. Uno de ellos, Lantern Keep, es un juego completo: menús, ranuras de partida,
servicios de tienda, opciones de accesibilidad, cuatro idiomas y ajustes listos para las tiendas.

La CI compila y prueba cada pull request y cada push a `main` en Linux, Windows
(MSVC) y macOS, y compila la app de iOS para el simulador y la librería y el APK de
Android, y los ejecuta en el simulador de iOS y en un emulador de Android (no en
dispositivos reales; véase [docs/MOBILE.md](docs/MOBILE.md), en inglés). Carencias abiertas y
próximos hitos: [feedback/ROADMAP.md](feedback/ROADMAP.md) (en inglés).

## Descarga

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

## Inicio rápido (compilar desde el código fuente)

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
- [docs/reference/README.md](docs/reference/README.md): referencia de la API navegable, una pagina por categoria de componentes y de comandos (generada, en ingles).
- [docs/COMPONENTS.md](docs/COMPONENTS.md): todos los componentes y campos en un solo archivo (generado).
- [docs/EXTENDING.md](docs/EXTENDING.md): crear herramientas, comandos, componentes y sistemas.
- [docs/CLI.md](docs/CLI.md) y [docs/MCP.md](docs/MCP.md): la CLI `factoria` y el servidor MCP.
- [docs/EDITOR.md](docs/EDITOR.md): el editor visual, centrado en la IA (en inglés): vista del juego, chat con la IA, selección, registro de audio.
- [docs/AI_PROVIDERS.md](docs/AI_PROVIDERS.md): proveedores de IA (Claude Code, Codex, claves de API) y roles.
- [docs/ASSETS.md](docs/ASSETS.md): generar e importar arte, sonido y modelos; ajustes de importación y procedencia.
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): cómo las IAs registran lo que le falta al motor.
- [docs/BUILDING.md](docs/BUILDING.md): requisitos por plataforma, presets, CI, tests y solución de problemas.
- [docs/MOBILE.md](docs/MOBILE.md) y [docs/EXPORTING.md](docs/EXPORTING.md): iOS/Android y exportar juegos.
- [docs/LOCALIZATION.md](docs/LOCALIZATION.md): varios idiomas: tablas de textos, campos `key` y la API de scripts `i18n` (en inglés).

Si vas a modificar el motor, lee primero [CLAUDE.md](CLAUDE.md) y
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Licencia

FactorIA es código abierto bajo la [licencia MIT](LICENSE): puedes usarlo, modificarlo y publicar juegos con él,
gratuitos o comerciales, siempre que el aviso de copyright y la licencia acompañen al código del motor.

- **Tus juegos son tuyos.** Los archivos que `factoria new` pone en un proyecto son [MIT-0](templates/LICENSE) (no
  hace falta ningún aviso). Un juego exportado contiene el runtime de FactorIA, así que `factoria export` escribe
  `FACTORIA_NOTICES.txt` con las licencias del motor y del código de terceros que lleva dentro; inclúyelo en lo que
  distribuyas ([docs/EXPORTING.md](docs/EXPORTING.md#license-notices), en inglés).
- **Código de terceros**: lo que hay en `external/` mantiene su propia licencia ([external/VERSIONS.md](external/VERSIONS.md);
  todas MIT, zlib o dominio público). `factoria docs licenses` muestra todos los avisos; las descargas los incluyen
  en `THIRD_PARTY_NOTICES.txt`.
- **El nombre.** La licencia cubre el código, no el nombre ni el logo de FactorIA. Puedes decir que tu juego está
  "hecho con FactorIA"; un motor modificado o redistribuido no debe presentarse como FactorIA, ni como respaldado por
  FactorIA, sin permiso.
