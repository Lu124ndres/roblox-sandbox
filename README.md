# roblox-sandbox

Base de desarrollo para un juego de Roblox, construida con Luau estricto, Rojo y un
flujo de trabajo pensado para código revisable y mantenible.

## Qué demuestra este proyecto

- **Código fuera de Studio.** Todo el código vive en el sistema de archivos y se
  sincroniza con Rojo, con historial en git y commits por tarea.
- **Luau con `--!strict` en todos los archivos**, con tipos exportados para los módulos
  compartidos.
- **Servidor autoritativo.** El cliente solo pide; el servidor decide dinero, progresión e
  inventario, y valida tipo, rango y permiso en cada RemoteEvent.
- **Configuración centralizada.** Números de balance en `Config.luau`, IDs de assets en
  `Assets.luau`, constantes visuales en `UIConfig.luau`. Nada de valores mágicos ni IDs
  inline.
- **Herramientas reproducibles.** Versiones fijadas con Rokit; linting con selene y
  formateo con stylua como parte del checklist de cada tarea.
- **Alcance controlado.** Desarrollo en dos fases (primero mecánicas con primitivas,
  después arte) y un registro explícito de ideas que no se implementan.
- **Decisiones documentadas.** Cada elección técnica no obvia tiene contexto,
  alternativas y justificación en `docs/decisiones.md`.

## Stack y herramientas

| Herramienta | Versión | Uso |
|---|---|---|
| Luau | — | Lenguaje, modo estricto |
| Rojo | 7.7.1 | Sincronización entre archivos y Studio |
| selene | 0.32.0 | Linter |
| StyLua | 2.6.0 | Formateador |
| Wally | 0.3.2 | Gestor de paquetes |
| Rokit | — | Gestor de versiones de las herramientas anteriores |
| MCP de Studio | — | Inspección y pruebas en Studio desde el asistente |
| Blender | — | Modelado (fase 2) |

## Estructura del repositorio

```
src/
  server/    -> ServerScriptService.Server
  client/    -> StarterPlayer.StarterPlayerScripts.Client
  shared/    -> ReplicatedStorage.Shared
assets/
  blender/
  textures/
docs/
  capturas/
```

- **`src/server/`**: lógica autoritativa. Estado de jugadores, economía, guardado y
  validación de toda petición que llega del cliente.
- **`src/client/`**: input, interfaz y efectos locales. No decide estado; envía
  peticiones al servidor y presenta el resultado.
- **`src/shared/`**: módulos que usan ambos lados.
  - `Config.luau`: todos los números de balance.
  - `Assets.luau`: todos los `rbxassetid`, agrupados en `UI`, `Textures` y `Animations`.
  - `UIConfig.luau`: colores, fuentes, tamaños, espaciados y curvas de animación.
- **`assets/blender/`**: archivos fuente y exportaciones de modelos 3D (fase 2).
- **`assets/textures/`**: PNG fuente de UI y texturas antes de subirlos a Roblox.
- **`docs/`**: setup, decisiones técnicas, devlog, ideas fuera de alcance, seguimiento
  de assets y pipeline de Blender.
- **`docs/capturas/`**: imágenes para este README y el devlog.
- **`CLAUDE.md`**: reglas y convenciones del proyecto, usadas también como contexto para
  desarrollo asistido por IA.

## Cómo levantarlo

Requisitos: Windows, Roblox Studio y [Rokit](https://github.com/rojo-rbx/rokit).

1. Clonar el repositorio:
   ```
   git clone https://github.com/Lu124ndres/roblox-sandbox.git
   cd roblox-sandbox
   ```
2. Instalar las herramientas en las versiones fijadas:
   ```
   rokit install
   ```
3. Instalar el plugin de Rojo en Studio:
   ```
   rojo plugin install
   ```
4. Iniciar el servidor de Rojo:
   ```
   rojo serve
   ```
5. Abrir una Baseplate en Studio y, en la pestaña Plugins, hacer clic en Rojo → Connect.
6. Presionar Play. En Output deben aparecer `servidor conectado via Rojo` y
   `cliente conectado via Rojo`.

Para generar un archivo de lugar sin Studio abierto:

```
mkdir build
rojo build --output build/test.rbxl
```

La carpeta `build/` está en `.gitignore` y no viene en el clon. Hay que crearla antes
del primer `rojo build`; si no existe, Rojo falla con `failed to create file`.

Verificaciones de calidad:

```
selene src
stylua src
```

## Decisiones de diseño

Detalle completo en [`docs/decisiones.md`](docs/decisiones.md).

- **Luau estricto en lugar de roblox-ts.** El tipado de Luau es suficiente y evita una
  capa de compilación. El código que se ejecuta es el mismo que se lee, y cualquier
  desarrollador de Roblox puede mantenerlo sin conocer TypeScript.
- **Rojo en lugar de editar en Studio.** Pone el código bajo control de versiones y
  permite linting, formateo y revisión de diffs. Studio se reserva para construir el nivel.
- **Primero mecánicas, después arte.** La fase 1 usa solo partes primitivas hasta tener
  un juego completo. Como los IDs y nombres están centralizados, sustituir primitivas
  por modelos en la fase 2 no requiere tocar la lógica.
- **Animación por código.** TweenService y CFrame en lugar de rigs: las animaciones
  viven en git, se ajustan desde `UIConfig.luau` y no dependen de assets externos.

## Juego publicado y capturas

<!-- TODO: agregar link al juego publicado en Roblox. -->
<!-- TODO: agregar capturas desde docs/capturas/. -->

Pendiente.

## Estado del proyecto

Entorno base configurado. El juego todavía no está definido: el repositorio contiene la
estructura, las herramientas, las convenciones y una prueba de humo de sincronización.
El progreso por sesión se registra en [`docs/devlog.md`](docs/devlog.md).

## Licencia

[MIT](LICENSE) © 2026 Lu124ndres
