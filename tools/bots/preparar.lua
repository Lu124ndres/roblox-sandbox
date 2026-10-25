-- Mete (o quita) los bots de prueba en Studio, en modo Edit, leyendo los archivos de
-- tools/bots por HTTP (antes: python -m http.server 34998 --directory tools/bots).
-- Pegar en la barra de comandos de Studio o correrlo por el MCP:
--     QUITAR = false  -- true para borrar los bots
-- Después: Prueba → Clientes y servidores → Servidor local, con 2 a 8 jugadores.
-- Los scripts van fuera de las carpetas que sincroniza Rojo (ServerScriptService y
-- StarterPlayerScripts, al lado de Server y Client), así Rojo no los toca.
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local QUITAR = QUITAR or false
local BASE = "http://localhost:34998/"

local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
for _, old in { ServerScriptService:FindFirstChild("BotMonitor"), scripts:FindFirstChild("Bot") } do
	if old then
		old:Destroy()
	end
end
if QUITAR then
	return "bots quitados"
end

local wasEnabled = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local ok, err = pcall(function()
	local monitor = Instance.new("Script")
	monitor.Name = "BotMonitor"
	monitor.Source = HttpService:GetAsync(BASE .. "Monitor.server.luau")
	monitor.Parent = ServerScriptService

	local bot = Instance.new("LocalScript")
	bot.Name = "Bot"
	bot.Source = HttpService:GetAsync(BASE .. "Bot.client.luau")
	bot.Parent = scripts
end)
HttpService.HttpEnabled = wasEnabled
assert(ok, err)
return "bots listos"
