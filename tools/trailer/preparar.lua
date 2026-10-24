-- Mete (o quita) el director del tráiler en Studio, en modo Edit, leyendo los archivos de
-- tools/trailer por HTTP (antes: python -m http.server 34999 --directory tools/trailer).
-- Pegar en la barra de comandos de Studio o correrlo por el MCP:
--     QUITAR = false  -- true para borrar el director
--     IDIOMA = "es"   -- o "en"
-- Los scripts van fuera de las carpetas que sincroniza Rojo (ServerScriptService y
-- StarterPlayerScripts, al lado de Server y Client), así Rojo no los toca.
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local QUITAR = QUITAR or false
local IDIOMA = IDIOMA or "es"
local BASE = "http://localhost:34999/"

local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
for _, old in { ServerScriptService:FindFirstChild("TrailerDirector"), scripts:FindFirstChild("TrailerDirector") } do
	if old then
		old:Destroy()
	end
end
Workspace:SetAttribute("TrailerEscena", nil)
Workspace:SetAttribute("HoraFija", nil)
if QUITAR then
	Workspace:SetAttribute("TrailerIdioma", nil)
	return "director quitado"
end

local wasEnabled = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local function fetch(name: string): string
	return HttpService:GetAsync(BASE .. name)
end
local ok, err = pcall(function()
	local server = Instance.new("Script")
	server.Name = "TrailerDirector"
	server.Source = fetch("Director.server.luau")
	server.Parent = ServerScriptService

	local client = Instance.new("LocalScript")
	client.Name = "TrailerDirector"
	client.Source = fetch("Director.client.luau")
	local camara = Instance.new("ModuleScript")
	camara.Name = "Camara"
	camara.Source = fetch("Camara.luau")
	camara.Parent = client
	local textos = Instance.new("ModuleScript")
	textos.Name = "Textos"
	textos.Source = fetch("Textos.luau")
	textos.Parent = client
	client.Parent = scripts
end)
HttpService.HttpEnabled = wasEnabled
assert(ok, err)
Workspace:SetAttribute("TrailerIdioma", IDIOMA)
return `director listo ({IDIOMA})`
