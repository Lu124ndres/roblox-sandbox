# Setup del entorno

Registro de lo instalado y de lo que falta conectar a mano.
Sistema: Windows. Las acciones marcadas **[clic]** se hacen en una interfaz gráfica;
las marcadas **[terminal]** se ejecutan en PowerShell desde la raíz del repositorio.

## Ya instalado

| Herramienta | Versión | Cómo se instaló |
|---|---|---|
| Rokit | — | winget |
| rojo | 7.7.1 | Rokit (`rokit.toml`) |
| selene | 0.32.0 | Rokit (`rokit.toml`) |
| stylua | 2.6.0 | Rokit (`rokit.toml`) |
| wally | 0.3.2 | Rokit (`rokit.toml`) |

En una máquina nueva, después de instalar Rokit, todas las herramientas se instalan con:

```powershell
rokit install
```

Verificación:

```powershell
rojo --version
selene --version
stylua --version
wally --version
```

## Pendiente de conectar

### 1. Plugin de Rojo en Studio

- [ ] **[terminal]** Instalar el plugin en la carpeta de plugins de Studio:
  ```powershell
  rojo plugin install
  ```
  > Pueden quedar varias versiones del plugin de Rojo instaladas a la vez. Solo debe
  > quedar la que coincide con el CLI (7.7.1); si hay otras, Studio puede conectarse
  > con la equivocada. Revisar **Plugins** → **Manage Plugins** (versiones de la tienda)
  > y la carpeta `%LOCALAPPDATA%\Roblox\Plugins` (donde `rojo plugin install` deja
  > `RojoManagedPlugin.rbxm`), y quitar las demás.
- [ ] **[clic]** Abrir Roblox Studio con una Baseplate vacía.
- [ ] **[terminal]** Levantar el servidor de Rojo:
  ```powershell
  rojo serve
  ```
- [ ] **[clic]** En Studio: pestaña **Plugins** → **Rojo** → **Connect**.
- [ ] **[clic]** Presionar **Play** y confirmar en Output:
  `servidor conectado via Rojo` y `cliente conectado via Rojo`.

### 2. MCP de Studio

El MCP viene integrado en Roblox Studio; no hay que instalar nada aparte.

> No usar `Roblox/studio-rust-mcp-server`: está descontinuado.

- [ ] **[clic]** En Studio: abrir el panel **Asistente** → menú de tres puntos → activar
  el servidor MCP. Al activarlo, Studio crea `%LOCALAPPDATA%\Roblox\mcp.bat`, que
  lanza el ejecutable del servidor.
- [x] La configuración del MCP para Claude Code vive en `.mcp.json`, en la raíz del
  repositorio: registra `roblox-studio` como servidor stdio que ejecuta
  `cmd.exe /c ${LOCALAPPDATA}\Roblox\mcp.bat`. Claude Code expande `${LOCALAPPDATA}`
  al cargar el archivo, así que funciona en cualquier máquina sin exponer el usuario.
- [ ] **[clic]** Recargar VS Code (**Ctrl+Shift+P** → **Developer: Reload Window**) para
  que Claude Code lea `.mcp.json`. La primera vez pide aprobar el servidor del proyecto.
- [ ] **[clic]** Con Studio abierto, verificar que las herramientas de Studio aparecen
  en la sesión (`/mcp` muestra `roblox-studio` como conectado).

### 3. Addon de Blender MCP (necesario hasta la fase 2)

Repositorio: <https://github.com/ahujasid/blender-mcp>

- [ ] **[terminal]** Instalar `uv`, que se usa para ejecutar el servidor:
  ```powershell
  winget install --id=astral-sh.uv -e
  ```
- [ ] **[clic]** Descargar `addon.py` del repositorio.
- [ ] **[clic]** En Blender: **Edit** → **Preferences** → **Add-ons** → **Install from Disk**
  → seleccionar `addon.py` → activar **Interface: Blender MCP**.
- [ ] **[terminal]** Registrar el servidor en Claude Code:
  ```powershell
  claude mcp add blender -- uvx blender-mcp
  ```
- [ ] **[clic]** En Blender, en la vista 3D: tecla **N** → pestaña **BlenderMCP** →
  **Connect to Claude**.

### 4. Repositorio remoto

- [ ] **[clic]** Crear el repositorio público `roblox-sandbox` en
  github.com/Lu124ndres, sin README ni licencia (ya existen aquí).
- [ ] **[terminal]**
  ```powershell
  git remote add origin https://github.com/Lu124ndres/roblox-sandbox.git
  git branch -M main
  git push -u origin main
  ```
