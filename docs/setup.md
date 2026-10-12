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
- [ ] **[clic]** Abrir Roblox Studio con una Baseplate vacía.
- [ ] **[terminal]** Levantar el servidor de Rojo:
  ```powershell
  rojo serve
  ```
- [ ] **[clic]** En Studio: pestaña **Plugins** → **Rojo** → **Connect**.
- [ ] **[clic]** Presionar **Play** y confirmar en Output:
  `servidor conectado via Rojo` y `cliente conectado via Rojo`.

### 2. MCP de Studio

Servidor oficial: <https://github.com/Roblox/studio-rust-mcp-server>

- [ ] **[clic]** Descargar el instalador de la última release del repositorio y ejecutarlo.
  Instala el plugin de Studio y registra el servidor en los clientes compatibles que detecte.
- [ ] **[clic]** Reiniciar Roblox Studio y confirmar en la pestaña **Plugins** que el
  plugin de MCP aparece y está activo.
- [ ] **[terminal]** Si el cliente es Claude Code y el instalador no lo registró, agregarlo
  a mano (ajustar la ruta al ejecutable según el README del repositorio):
  ```powershell
  claude mcp add roblox-studio -- "C:\ruta\a\rbx-studio-mcp.exe" --stdio
  ```
- [ ] **[clic]** Reiniciar el cliente de IA y verificar que las herramientas de Studio aparecen.

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

- [ ] **[clic]** Crear el repositorio público `sandbox` (o el nombre elegido) en
  github.com/Lu124ndres, sin README ni licencia (ya existen aquí).
- [ ] **[terminal]**
  ```powershell
  git remote add origin https://github.com/Lu124ndres/<nombre-del-repo>.git
  git branch -M main
  git push -u origin main
  ```
