# Auditoría externa de FactorIA 0.21.0

Fecha: 2026-11-10. Commit auditado: `main` tras el PR #207 (M91, versión 0.21.0).

Este informe es la opinión de un revisor externo, escrita para el agente que desarrolla el motor. No es una
lista de órdenes: es lo que vi, con la prueba de cada cosa, y lo que yo haría. Lo que ya está en
`feedback/ROADMAP.md` no lo repito; solo digo si cambiaría su orden. Cada hallazgo lleva una marca:

- **[nuevo]**: no está en ningún hito.
- **[Mxx]**: ya está planificado en ese hito.

## Cómo se hizo y qué no cubre

Usé tres fuentes:

1. `feedback/ROADMAP.md` y `feedback/ROADMAP_DONE.md`, para saber qué está hecho, qué está pendiente y qué se
   decidió no hacer.
2. El binario instalado (`factoria` 0.21.0), usado como lo usaría una IA que hace un juego: `factoria new`,
   `validate`, `test`, `run --headless`, `mcp`, `docs`, y un proyecto con errores puestos a propósito.
3. El código (`engine/core`, `engine/scene`, `engine/script`, `tools/common`, `tools/cli`) y los flujos de CI.

No cubre: una compilación desde cero, los exports a móvil y web, el editor visual, ni una lectura línea a
línea de `render`, `physics` y `audio`. De esos módulos solo opino sobre tamaño y estructura.

## 1. Veredicto en corto

- La idea central funciona y se nota al usarlo: todo es texto, el ciclo editar-validar-probar tarda décimas
  de segundo y los errores de JSON y de comandos enseñan de verdad.
- El motor incumple hoy su propia promesa en tres sitios: los errores de los scripts (engañan o no dicen
  nada), el coste de contexto del primer paso (documentación y lista de herramientas MCP) y los tests que
  pasan aunque los scripts del juego lancen errores.
- El bucle de feedback, que es el mejor invento del proyecto, lleva dos semanas sin triaje para los juegos
  del propio repo: hay 36 entradas abiertas en los ejemplos y el roadmap cuenta 3.
- Sobra plan, no código: hay 19 hitos de render, arte y editor (M71–M89) que ningún juego ha pedido, por
  delante de 33 problemas que los juegos sí han encontrado.
- La documentación es exacta y honesta, pero está escrita para leerse entera y nadie puede leerla entera:
  4,4 MB en `docs/`, y el primer paso que se le manda a la IA cuesta unos 70.000 tokens.

## 2. Lo que hace bien

**El ciclo es rapidísimo.** Medido en un proyecto recién creado: `factoria new` 0,06 s; `validate` 0,07 s;
`test` con 10 tests 0,11 s; 120 fotogramas sin ventana con captura e informe JSON 0,10 s. Para una IA esto
vale más que cualquier función nueva, porque puede comprobar cada cambio en vez de suponer.

**Los errores de JSON y de comandos enseñan.** Un campo, componente, comando, argumento, acción de entrada o
ruta mal escritos devuelven el archivo, el puntero JSON, la sugerencia más cercana, la lista válida y la
frase de documentación del campo. Un campo de componente mal escrito desde un script también:
`RigidBody2D has no field 'velocty'. Did you mean 'velocity'? Fields: …`. Este es el listón; el apartado 3
señala dónde no se llega a él.

**Un registro, todas las superficies.** `CommandRegistry` (`engine/core/include/fa/core/command.h`) y
`TypeRegistry` (`reflect.h`) están bien diseñados y bien explicados. Que un comando registrado una vez
aparezca en MCP, CLI, consola del editor y `fa.call` evita que las superficies se separen.

**Volumen y tipo de pruebas.** 4.929 `TEST_CASE` en 442 archivos de test, unos 1.594 tests JS en los
ejemplos, y los juegos de ejemplo corren como tests de `ctest` con presupuestos de rendimiento y hashes de
repetición en todas las plataformas. Los juegos como tests del motor son una decisión excelente.

**CI amplio.** Linux, Steam Runtime, Windows, macOS, iOS en simulador, web en Chrome sin ventana y Android
con emulador. Poca gente con un motor de un mes tiene esto.

**Higiene y honestidad.** Un solo `TODO/FIXME/HACK` en el código propio. El roadmap dice qué quedó sin hacer
("Left open") y comprueba contra el código lo que afirma una revisión antes de aceptarlo.

**El bucle de feedback, como diseño.** `ENGINE_FEEDBACK.json` por juego, 342 entradas en 11 ejemplos, la
mayoría `fixed-in-engine` con su nota. Hasta M42 casi todos los paquetes del roadmap citan la entrada de la
que nacen.

**Las skills son pequeñas.** 11 skills en 23 KB. Es el tamaño correcto y el modelo a seguir para el resto de
la documentación.

## 3. Lo que hace mal

Ordenado por lo que más daña a una IA que hace un juego.

### 3.1 Un nombre de API mal escrito da una pista falsa — [nuevo]

Un script con `input.axs("move")` o `world.findById(1)` produce:

```
TypeError: not a function (the engine's 'input' from "factoria" has no 'axs'; this player may be older
than the game's engine, if input is that object)
hint: The game was made with a newer FactorIA than the player running it. Run `factoria setup players`
and export again…
```

El motor sabe el objeto y el miembro que falta, pero manda a la IA a reinstalar los reproductores. Es el
error más probable en un script y recibe la peor pista.

Causa, en `engine/script/src/script_system.cpp`: `explain_missing_api` añade siempre la cola
`"; this player may be older than the game's engine"`, y `hint_for` busca primero ese texto, antes que
`"not a function"`.

Arreglo (pequeño):

- En `explain_missing_api`, listar los miembros reales del objeto y proponer el más parecido
  (`closest` ya existe en `factoria.js`, línea 20): `'input' has no 'axs'. Did you mean 'axis'?`.
- Mencionar el reproductor antiguo solo cuando el código corre en el reproductor exportado. En
  `factoria test`, `run` y `mcp` el motor y el reproductor son el mismo binario y esa causa es imposible.

### 3.2 `Entity` y los matchers de test fallan sin explicar nada — [nuevo]

- `game.find("player").positon.x` → `TypeError: cannot read property 'x' of undefined`.
- `p.setPosition(1, 2)` → `TypeError: not a function`.
- `expect(1).toBeTruthy2()` → `TypeError: not a function`, sin la lista de matchers.
- `entity.get("Rigidbody2D")` (mayúscula mal) funciona en silencio; `entity.get("NoSuch")` no da la lista.

En `factoria.js` solo tienen Proxy estricto las vistas de componente (línea 379), los plugins (2608) y
`gameApi` (4506). `class Entity` (471) y los espacios de nombres (`input`, `world`, `audio`…) son objetos
normales.

Arreglo: en ejecuciones de desarrollo (`test`, `run`, `mcp`, editor) envolver `Entity`, los espacios de
nombres y el objeto de `expect` en el mismo Proxy estricto, con "did you mean" y lista. En el reproductor
exportado, sin Proxy, para no pagar el coste.

### 3.3 Los tests pasan aunque los scripts del juego lancen errores — [nuevo]

Con un script que lanza una excepción en cada fotograma, `factoria test` imprime
`PASS … player stands on the ground` y debajo el error del script. Un test que llama a `audio.play` con un
archivo que no existe pasa con una línea `ERROR audio:` en el log. El resumen los cuenta como aprobados.

Una IA lee el resumen y el código de salida. Si son verdes, sigue. Este es el fallo que más errores deja
entrar en un juego.

Arreglo: un test en el que un script del juego lanzó, o en el que el motor registró un `ERROR`, falla por
defecto. Para los tests que esperan el error, una forma explícita de decirlo
(por ejemplo `expectErrors(/texto/)`).

### 3.4 `validate` solo mira la sintaxis de los scripts — [nuevo]

Los nombres mal escritos sobre lo importado de `"factoria"` se pueden comprobar sin ejecutar nada contra
`types/factoria.d.ts`, y los archivos ya llevan `// @ts-check`. Hoy el error llega al ejecutar, y solo si
esa línea se ejecuta. M97.4 planea esta comprobación para los bloques de código de la documentación; hace
más falta en los juegos.

Arreglo: que `validate` compruebe al menos los miembros de los objetos importados de `"factoria"` y los
nombres de componente pasados como texto a `get`/`add`/`has`.

### 3.5 Falta el aviso para colores 0..255 — [nuevo]

`"color": [255, 255, 255, 255]` pasa `validate` con 0 avisos. `AGENTS.md` avisa de este error, así que el
motor sabe que es frecuente. Un aviso cuando un `Color` tiene algún canal mayor que 1 lo cierra.

### 3.6 Salida ruidosa y duplicada — [nuevo]

- `validate` sin `--json` imprime cada error dos veces (la línea de log `ERROR scene:` y la línea `error:`).
- Con `--json`, las líneas de log siguen saliendo por stderr.
- Una ejecución de tests con fallos imprimió 10.627 bytes: la misma traza repetida por cada test y la frase
  fija "(an exception was thrown inside the test; check the game scripts too…)".

Cada byte repetido es contexto de la IA. Arreglo: un error, una vez; una traza idéntica se imprime la
primera vez y después se cuenta ("el mismo error en 9 tests más").

### 3.7 `tools/list` de MCP pesa 1 MB — [M97.2, lo subiría]

Medido: 405 herramientas, 1.012.223 bytes, unos 250.000 tokens. Las descripciones suman 468.952 bytes. La
herramienta mediana ocupa 1.951 bytes; la mayor, `tilemap_generate`, 18.714. Arte y autoría son cerca del
60 % de los bytes (prefijos `assets`, `image`, `vector`, `model`, `music`, `anim3d`…).

Solo Claude Code (búsqueda de herramientas diferida) y el agente integrado (catálogo de M45.2) están a salvo.
Codex y cualquier otro cliente MCP lo cargan entero, y eso no cabe en una ventana de 200.000 tokens. `factoria mcp`
tiene `--read-only` pero no perfiles. Además las `instructions` del servidor (2.882 bytes) siguen diciendo
`docs_read {"name":"ai-guide"}`.

Arreglo, compatible con la decisión de mantener los comandos de arte en MCP:

- Perfil por defecto con las 40–60 herramientas del ciclo básico, más dos herramientas meta: buscar una
  herramienta y llamarla por nombre. El resto sigue disponible, pero no en la lista inicial.
- Presupuesto por descripción (por ejemplo 1,5 KB) comprobado por un test. Lo que no quepa va a
  `docs_read` con su encabezado.

### 3.8 El bucle de feedback está parado — [nuevo]

`factoria feedback collect examples/*` da hoy **36 entradas abiertas de 11 proyectos**.
`feedback/ROADMAP.md` (línea 52) cuenta **3 entradas de 9 proyectos**, y su orden de regeneración no incluye
`kindlewatch` ni `ember-descent`. El último párrafo de triaje es del 2026-10-27. Hay 33 entradas, escritas
entre el 2026-10-29 y el 2026-11-08, sin triaje ni hito: `ROADMAP.md` no nombra ninguna.

El propio roadmap lo prometió. M60 (Kindlewatch, el sexto juego de referencia) dice que el juego apunta cada
carencia "and a triage milestone turns them into packages, as after M21-M32". Ese hito de triaje no existe.

Las más graves:

| Entrada | Gravedad | Qué dice |
|---|---|---|
| Kindlewatch FB-0001 | major | `MusicPlayer` retiene cientos de MB de audio decodificado y las cifras de memoria no lo muestran (el juego lleva una línea base de más de 600 MB) |
| Kindlewatch FB-0002 | major | El esquema de `assets.json` rechaza la procedencia que escriben los propios `model.game_ready` y `model.bake` |
| Kindlewatch FB-0004 | major | Un fundido o cambio de sección pendiente de `MusicPlayer` sobrevive a una carga de escena |
| Gem Roller FB-0016 | major | Un script que llama a una herramienta del proyecto con `fa.call` funciona en el editor y en `factoria run` y falla en el reproductor exportado |

El resto: Kindlewatch FB-0006, 0008, 0012–0015, 0020, 0021 (21 abiertas en total); Gem Roller FB-0013 y
0014; Neon Swarm FB-0019–0022; Sky Hopper FB-0024–0026; Lantern Keep FB-0048; Ember Descent FB-0002.

En esas dos semanas el feedback de Roguestory, un juego de fuera del repo, sí se atendió (M44, M47, M49).
Pero también se planificaron 19 hitos propios (M71–M89) y los diez de la revisión externa (M90–M99), y los
juegos de ejemplo se quedaron sin triaje justo cuando el sexto juego de referencia dejó 21 entradas.

Arreglo:

- Triar las 33 entradas ahora y regenerar la lista con los 11 ejemplos.
- Un test de CI que falle si el recuento de `feedback collect examples/*` no coincide con el de
  `ROADMAP.md`, o si hay una entrada abierta con más de N días sin triaje. Que usar `examples/*` en vez de
  una lista escrita a mano evite que un juego nuevo quede fuera.

### 3.9 Estado desfasado en la portada — [nuevo; M90.1 ya lo corrigió una vez]

`README.md` dice "Version 0.19" y la versión es 0.21.0. M90.1 lo arregló y se desfasó en dos versiones, así
que hace falta un test que compare la versión del README con la de `CMakeLists.txt`, no otro arreglo a mano.
`README.es.md` y `docs/i18n/es/GETTING_STARTED.md` llevan un aviso de que el texto "sigue en la 0.1".

## 4. Lo que sobra o llega demasiado pronto

No borraría código. Lo que sobra es plan, superficie expuesta por defecto y copias.

**M71–M89, por orden, no por contenido.** Respeto la decisión de que FactorIA cubra todo tipo de juego. Mi
objeción es otra: son 19 hitos de HDR, sombreadores, iluminación, TAA, D3D12/Vulkan, trazado de rayos,
generación de fotogramas, herramientas de arte y memoria del editor, todos con origen "the user,
2026-11-06..09" (M83–M89, de marcadores de X), y ninguno cita una entrada de feedback. Muchas son buenas
ideas; lo que discuto es el orden. La regla que el propio roadmap usó en M19 ("take them when a game needs them") es la
correcta. Propongo aplicarla: cada uno de esos hitos empieza cuando un juego de referencia lo pide en su
`ENGINE_FEEDBACK.json`, y de uno en uno. Un motor para IAs gana más con que 11 juegos se hagan sin tropiezos
que con trazado de rayos que ningún juego usa.

**La lista inicial de MCP.** Los 170 comandos de arte pueden quedarse; lo que sobra es anunciarlos todos al
conectar (apartado 3.7).

**Tooling mayor que el motor.** `engine/` tiene unas 193.000 líneas; `tools/` unas 198.000
(`tools/common` 100.000, `tools/editor` 63.000, `tools/ai` 23.000). `tools/ai` reimplementa buena parte de un
arnés de agentes: proveedores, hooks, extensiones, instalación de plugins, cliente MCP, retrospectivas,
revisiones. Claude Code y Codex ya hacen eso y cambian cada mes. No pido quitarlo; pido no ampliarlo
(M87 y parecidos) mientras el camino básico con un cliente MCP externo tenga los problemas del apartado 3.

**`CLAUDE.md` duplicado.** Cada proyecto generado lleva `AGENTS.md` y un `CLAUDE.md` idéntico byte a byte
(14 KB cada uno). `CLAUDE.md` puede ser una línea: `@AGENTS.md`.

**Traducciones caducadas.** Un texto en español que avisa de que va veinte versiones por detrás es peor que
no tenerlo. O se genera con cada versión, o se quita y se deja solo el README traducido.

**Detalles.** `.mcp.json` fija `"timeout": 14400000` (4 horas): una llamada colgada bloquea al agente toda
la sesión. Los `tiles` del `Tilemap` son 2.400 enteros en línea dentro del JSON de la escena: ruido en cada
lectura y en cada diff (M94.2 lo toca por rendimiento; el coste de lectura es otra razón).

## 5. Lo que falta

**Una medida de la promesa principal — [nuevo].** No hay ningún número que diga cuánto le cuesta a una IA
sin contexto hacer un juego. Existe la base (`tools/common/src/efficiency.cpp` mide pasos y tokens de una
transcripción). Falta la prueba: un agente nuevo, solo con el binario descargado y un encargo fijo ("un
plataformas con tres niveles"), y se anotan tokens hasta el primer juego jugable, errores encontrados y
errores no detectados. Ese número, medido en cada versión, debería decidir prioridades más que ninguna
revisión, incluida esta.

**Prueba con otros clientes — [M92.4, ampliaría].** Los 11 juegos los hizo la misma familia de modelo, con
el mismo cliente y dentro del repo, con acceso al código del motor. `docs/AI_PROVIDERS.md` admite que Codex
es "the least tested". Un juego hecho con Codex y otro con un modelo pequeño, fuera del repo, encontrarán lo
que estos 11 no pueden encontrar.

**Lectura por partes en la CLI — [M97.2].** `factoria docs read <nombre>` no tiene `--heading`; solo lo
tiene `docs_read` de MCP. El `AGENTS.md` generado prefiere la CLI, así que la IA que sigue las
instrucciones no puede leer una sola receta.

**Oráculos independientes — [M93].** No hay `-fsanitize` ni fuzzing en CI, y `FA_WARNINGS_AS_ERRORS` está
apagado (`CMakeLists.txt:65`, sin activar en presets ni en CI). Con unos 75 commits al día revisados por
agentes de la misma familia de modelo, autor y revisor comparten puntos ciegos. Como se decidió no añadir
revisión humana, los oráculos mecánicos son la única revisión independiente que hay. Empezaría por
ASan+UBSan en el trabajo de Linux: es lo más barato y lo que más encuentra.

**Plantillas — [M97.5].** Solo hay 3 plantillas y los ejemplos no vienen en la descarga. Una IA aprende más
de un juego completo que funciona que de 280 KB de guía.

**Lo ya previsto en M98** (ranuras de guardado, interpolación de render, mandos, `TextField`, audio 3D) sí
son carencias que un juego real encuentra pronto. Las pondría antes que M71–M89.

## 6. Documentación

**Lo bueno.** Lo que leí es exacto, llano y honesto. `docs/MCP.md` admite sus propios números ("404 tools,
about 1 MB of definitions"). Los comentarios de cabecera del código explican el porqué. Las skills están
bien medidas.

**El problema es el tamaño y el camino de lectura.**

| Documento | Tamaño | Tokens aprox. |
|---|---|---|
| `docs/COMPONENTS.md` | 1.762 KB | 440.000 |
| `CHANGELOG.md` | 419 KB | 105.000 |
| `feedback/ROADMAP_DONE.md` | 288 KB | 72.000 |
| `docs/AI_GUIDE.md` | 282 KB | 70.000 |
| `docs/MENUS.md` | 257 KB | 64.000 |
| `feedback/ROADMAP.md` | 225 KB | 56.000 |
| `docs/EXPORTING.md` | 183 KB | 46.000 |
| `docs/SCRIPTING.md` | 169 KB | 42.000 |
| `docs/` entero | 4.410 KB | 1.100.000 |

- El paso 1 del `AGENTS.md` generado manda leer `ai-guide` (70.000 tokens) y después cita `scripting` y
  `components`. Una IA obediente gasta medio contexto antes de escribir una línea.
- `AI_GUIDE.md` tiene 14 secciones y la 9 (recetas 9.1–9.32) es casi todo el peso. Es un libro de recetas
  metido en una guía de inicio.
- `factoria docs list` enseña 44 documentos con título, sin tamaño ni para quién es cada uno.
- Los archivos de planificación del propio agente del motor (`ROADMAP.md` más `ROADMAP_DONE.md`) cuestan
  unos 130.000 tokens. El agente que desarrolla el motor sufre el mismo problema que el que hace juegos.

**Lo que haría** (M97.1 y M97.3 van en esta línea; lo concreto):

1. Tres niveles. `AGENTS.md` de menos de 6 KB con el ciclo y las diez reglas. Un índice de recetas de una
   línea cada una. La receta, bajo demanda, con `factoria docs read ai-guide --heading 9.12` o
   `factoria docs search`.
2. `docs list` con tamaño, tokens aproximados y audiencia (IA que hace juegos, persona, agente del motor).
3. Presupuesto de tamaño por documento, comprobado por un test, como ya propone M97.3.
4. `ROADMAP.md` solo con lo pendiente y lo decidido; los hitos cerrados, un archivo por hito en
   `feedback/done/`. `CHANGELOG.md` partido por versión mayor.
5. Tests que mantengan cierto lo que cambia solo: versión del README, recuento de herramientas en
   `docs/MCP.md`, recuento de ejemplos.

**Sobre el orden.** El roadmap dice que M97 va "at any time, alongside the others". No estoy de acuerdo.
En un motor cuyo usuario es una IA, el coste de lectura es rendimiento del producto, igual que los
fotogramas por segundo en un motor para personas. M97.1 y M97.2 deberían ir primeros.

## 7. Proceso, CI y riesgos de ingeniería

**`main` en rojo.** De los 16 runs de CI completados en `main` desde el 2026-10-31, 5 fallaron: los merges
de los PR #191, #192, #198, #204 y #206. Cuatro son merges de hito. O se fusiona sin esperar al verde, o las
puertas son inestables. En los dos casos el verde deja de significar algo.

**Puertas de rendimiento ruidosas.** Hay commits "CI fix" que vuelven a medir las líneas base de
rendimiento y memoria por cada runner. Un umbral que se reajusta cuando falla no protege. Propuesta: que la
puerta use contadores deterministas (llamadas de dibujo, asignaciones, entidades procesadas, bytes
retenidos) y que el tiempo de reloj sea solo informe; o comparar contra `main` compilado en el mismo
trabajo.

**CI lento.** Unos 80 minutos por run y límites de 90. Con 75 commits al día, el CI es el cuello de botella
y empuja a fusionar sin esperar. Añadir sanitizers (M93) lo empeora si no se separa: un trabajo rápido
obligatorio (compilar, tests unitarios, `validate` de ejemplos) y uno completo por hito.

**Estructura — [M94, M96].** `World` mezcla el ECS con una docena de estados globales (márgenes seguros,
escala de UI, idioma, `FeelState`, `MeshStore`…); `each` copia un vector de entidades en cada consulta;
`TypeRegistry::global()` es un singleton de proceso. Archivos muy grandes: `autotest_tools.cpp` 9.755
líneas, `factoria.js` 4.655, `script_natives.cpp` 4.261, `audio.cpp` 3.400. Hay 37 `catch (...)` y 103
`reinterpret_cast` en `engine/`. Ninguno es un fallo demostrado; son los sitios donde yo apuntaría primero
los sanitizers y el fuzzing.

**Tamaño — [M96].** `factoria` 151,8 MB, `factoria_player` 36,2 MB (macOS universal),
`factoria_player.wasm` 13,5 MB. Para web y móvil, el reproductor es grande. De acuerdo con M96 y con
ponerlo antes de M89.3.

**Ritmo.** 2.120 commits en 28 días. La velocidad es real y el resultado es coherente, lo que dice mucho
del proceso. Pero el plan crece más deprisa que la comprobación: el roadmap pendiente tiene 27 hitos
nuevos (M71–M89 y M92–M99), más los restos de M8, M12 y M19.
Mi consejo es una regla simple: no se añade un hito propio mientras haya entradas de feedback sin triar.

**Nota local.** En esta máquina, `build/macos-release` es del 22 de octubre y el test `runtime` falla ahí
(`runtime_tests.cpp:168`, el esquema de proyecto cambió el 8 de noviembre). No es un fallo de `main`; el CI
del PR #207 está en verde. Hay que recompilar ese directorio.

## 8. Orden que yo seguiría

**Primero (días, cambios pequeños, todo nuevo):**

1. Triar las 33 entradas de feedback y añadir el test que impide que vuelva a pasar (3.8). Dentro del
   triaje, primero Kindlewatch FB-0001, FB-0002, FB-0004 y Gem Roller FB-0016.
2. Errores de script que enseñen: `explain_missing_api`, Proxy estricto en `Entity`, espacios de nombres y
   `expect` (3.1, 3.2).
3. Un test falla si un script del juego lanzó o el motor registró un error (3.3).
4. Test de la versión del README (3.9).

**Segundo (la promesa principal):**

5. M97.1 y M97.2: `AGENTS.md` corto, índice, `docs read --heading`, perfiles de MCP y presupuesto por
   descripción (3.7, apartado 6).
6. `validate` comprueba los scripts contra `types/factoria.d.ts` y avisa de colores 0..255 (3.4, 3.5).
7. Una sola salida, sin duplicados (3.6).
8. La medida de coste con un agente sin contexto (apartado 5), para tener un número antes y después.

**Tercero:** M92 y M93 como están, empezando M93 por ASan+UBSan en Linux y por separar el CI rápido del
completo.

**Cuarto:** M94, M95 y M96, cada paquete con su medida antes y después (M93.5). Después, M98.

**Al final y bajo demanda:** M71–M89, cada uno cuando un juego lo pida.

## Apéndice: medidas

Todas tomadas el 2026-11-10 con `factoria` 0.21.0 en macOS, salvo que se diga otra cosa.

| Qué | Valor |
|---|---|
| `factoria new` (plantilla `2d-platformer`) | 0,06 s |
| `factoria validate` | 0,074 s |
| `factoria test` (10 tests) | 0,11 s |
| `run --headless` 120 fotogramas + captura + JSON | 0,096 s |
| MCP `tools/list` | 405 herramientas, 1.012.223 bytes |
| Suma de descripciones de herramientas | 468.952 bytes |
| Herramienta mediana / mayor | 1.951 / 18.714 bytes (`tilemap_generate`) |
| `instructions` del servidor MCP | 2.882 bytes |
| `docs/*.md` | 4,41 MB, 44 documentos embebidos |
| `AGENTS.md` generado (y `CLAUDE.md` idéntico) | 14 KB cada uno |
| Skills | 11, 23.296 bytes |
| Feedback abierto según `feedback collect` | 36 entradas, 11 proyectos |
| Feedback abierto según `ROADMAP.md` | 3 entradas, 9 proyectos |
| `TEST_CASE` de doctest | 4.929 en 442 archivos |
| Tests JS en ejemplos y plantillas | unos 1.594 en 144 archivos |
| Código propio | `engine/` ≈ 193.000 líneas, `tools/` ≈ 198.000 |
| Binarios | `factoria` 151,8 MB; `factoria_player` 36,2 MB; wasm 13,5 MB |
| CI en `main` desde 2026-10-31 | 11 verdes, 5 rojos, 2 cancelados |
| Duración de un run de CI | ≈ 80 min (PR #207: 1 h 23 min) |
| Ritmo | 2.120 commits en 28 días |

Entradas abiertas por juego: kindlewatch 21, neon-swarm 4, gem-roller 3, sky-hopper 3, tidewater-market 3,
lantern-keep 1, ember-descent 1.

Tests locales ejecutados: `core`, `scene`, `script`, `physics`, `mcp`, `example_block-push_test` y
`example_lantern-keep_test` pasan; `runtime` falla por el directorio de compilación antiguo (apartado 7).
