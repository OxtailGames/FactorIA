# Respuestas de privacidad (Clockwork Courier 1.0.0)

Datos para rellenar los formularios de las tiendas (lo que dice el propio motor está en MOBILE.md de la documentación de FactorIA, "Store privacy forms"). Mira el formulario vigente de cada tienda: cambian.

## Qué hace el juego
- Sin cuentas, sin analítica, sin identificador publicitario y sin conexión de red propia.
- Las partidas (mejores resultados, ajustes, la marca de "intro vista") son archivos en la carpeta privada de la aplicación. Nada los envía a ningún sitio.
- Servicios opcionales de la plataforma: Game Center / iCloud clave-valor (iOS, macOS) y Play Games (Android) para logros, clasificaciones y la copia de la partida en la nube. Solo se usan si el jugador ha iniciado sesión en la plataforma; el juego no recibe nombre ni correo.
- Las compras pasan por la tienda (StoreKit, Play Billing). El juego nunca ve datos de pago.
- El anuncio con recompensa de "más tiempo" es un sustituto en esta versión. Un SDK de anuncios real recogería datos (identificadores del dispositivo, ubicación aproximada, datos de uso) y habría que añadirlo a las respuestas.

## Apple App Store (Privacidad de la app)
- Tipos de datos recogidos: ninguno. ("Datos no recopilados.")
- Seguimiento: no. `NSPrivacyTracking` es false (en factoria.json, `export.ios.privacy.tracking`).
- APIs de motivo obligatorio: se declaran solas en PrivacyInfo.xcprivacy con `factoria export --platform ios` (FileTimestamp C617.1, SystemBootTime 35F9.1).
- Cumplimiento de exportación: `usesNonExemptEncryption` false (sin criptografía propia; solo el HTTPS del sistema, cuando lo usa un servicio de la plataforma).
- URL de la política de privacidad: obligatoria (mira urls.txt).

## Google Play (Seguridad de los datos)
- ¿La app recoge o comparte datos de usuario?: No, con el sustituto de anuncios. Con un SDK real: Sí, identificadores del dispositivo y actividad en la app, para publicidad; rellénalo con la declaración del propio SDK.
- ¿Se cifran los datos en tránsito?: Sí (los servicios de la plataforma usan TLS; el juego no envía nada por sí mismo).
- ¿Pueden los usuarios pedir que se borren sus datos?: el juego no guarda datos en un servidor nuestro. Los datos locales se van al desinstalar; la copia en la nube es el almacenamiento propio del jugador en Play Games o iCloud.
- Público objetivo: no son niños (no aplica la política de Familias).
- Declaración de anuncios: marca "contiene anuncios" solo cuando conectes una red publicitaria real.

## Steam e itch.io
- Steam: el juego no recoge datos. El plugin de Steamworks solo habla con el cliente de Steam.
- itch.io: no se recogen datos.

## Política de privacidad
Todas las tiendas piden una URL. Una política breve puede decir: el juego no recoge datos personales, guarda el progreso en el dispositivo, usa los servicios de la plataforma solo si inicias sesión en ellos, e indica un correo de contacto. Escríbela y publícala tú (mira urls.txt).
