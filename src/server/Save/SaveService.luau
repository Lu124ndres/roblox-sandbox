--!strict
--[[
	SaveService

	Ciclo de vida del guardado de cada jugador:
		- Al entrar: leaderstats en cero y carga en segundo plano. Si otro
		  servidor todavía tiene sus datos abiertos (acaba de cambiar de
		  servidor), espera y reintenta; si no se liberan, lo expulsa con un
		  mensaje amable antes que arriesgar sus datos.
		- Cada autosaveSeconds: guarda a todos (y renueva el bloqueo),
		  repartidos a lo largo del intervalo y no todos en el mismo frame.
		- Al salir: guarda y suelta el bloqueo, una sola vez por jugador (al
		  cerrar el servidor corren a la vez PlayerRemoving y BindToClose).
		  Si sale mientras carga, la carga suelta el bloqueo y no lo adjunta.
		- Al cerrar el servidor (BindToClose): guarda a todos a la vez con
		  menos reintentos (SaveStore.shuttingDown) y espera a que terminen,
		  también las salidas que ya habían empezado (el último en salir).
		Nunca se guarda un perfil que no terminó de cargar (PlayerData.snapshot
		da nil) ni datos corruptos o de una versión más nueva (SaveStore).
	El estado vive en PlayerData; el DataStore, en SaveStore.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.Parent.PlayerData)
local SaveStore = require(script.Parent.SaveStore)

local SAVING = Config.Saving
local LOCKED_MESSAGE = "Tus datos siguen abiertos en otro servidor. Vuelve a entrar en un minuto."
local ERROR_MESSAGE =
	"No pudimos cargar tus datos. Vuelve a entrar en un momento; no se perdió nada."
local NEWER_MESSAGE = "El juego se actualizó. Vuelve a entrar para jugar la versión nueva."

local SaveService = {}

local saving: { [Player]: boolean } = {} -- evita dos guardados del mismo jugador a la vez
-- Jugadores que ya empezaron a salir (claves débiles: no retienen al Player).
local gone: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local leaving: { [Player]: boolean } = {} -- salida en curso (guardado final)

local function load(player: Player)
	PlayerData.prepare(player)
	for _ = 1, SAVING.lockedRetries do
		local status, data = SaveStore.acquire(player.UserId)
		if gone[player] or not player.Parent then
			if status == "ok" and data then
				SaveStore.write(player.UserId, data, true) -- se fue mientras cargaba: soltar
			end
			return
		end
		if status == "ok" and data then
			PlayerData.attach(player, data)
			return
		elseif status == "error" or status == "newer" then
			player:Kick(if status == "newer" then NEWER_MESSAGE else ERROR_MESSAGE)
			return
		end
		task.wait(SAVING.lockedRetrySeconds)
	end
	player:Kick(LOCKED_MESSAGE)
end

local function save(player: Player, release: boolean): boolean
	if saving[player] or (gone[player] and not release) then
		return false -- ya salió: solo la salida guarda (no vuelve a tomar el bloqueo)
	end
	local data = PlayerData.snapshot(player)
	if not data then
		return false -- nunca cargó: no hay nada propio que guardar
	end
	saving[player] = true
	local ok = SaveStore.write(player.UserId, data, release)
	saving[player] = nil
	return ok
end

local function onRemoving(player: Player)
	gone[player] = true
	if leaving[player] then
		-- Ya hay una salida en curso (BindToClose y PlayerRemoving a la vez): esperarla.
		while leaving[player] do
			task.wait(0.1)
		end
		return
	end
	leaving[player] = true
	-- Espera un guardado automático en curso para no soltar el bloqueo antes de tiempo.
	while saving[player] do
		task.wait(0.1)
	end
	save(player, true)
	PlayerData.detach(player)
	leaving[player] = nil
end

-- Guarda ya (compras con Robux): espera un guardado en curso y devuelve si se escribió.
function SaveService.saveNow(player: Player): boolean
	while saving[player] do
		task.wait(0.1)
	end
	return save(player, false)
end

function SaveService.init()
	Players.PlayerAdded:Connect(load)
	Players.PlayerRemoving:Connect(onRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	task.spawn(function()
		while true do
			local players = Players:GetPlayers()
			if #players == 0 then
				task.wait(SAVING.autosaveSeconds)
				continue
			end
			-- Uno cada autosaveSeconds / N: con 50 jugadores, uno cada ~1,2 s.
			local gap = SAVING.autosaveSeconds / #players
			for _, player in players do
				task.wait(gap)
				if player.Parent then
					task.spawn(save, player, false)
				end
			end
		end
	end)

	-- Cuando sale el último jugador, el servidor se cierra mientras su PlayerRemoving
	-- todavía guarda: GetPlayers() ya viene vacío y Roblox no espera a ese hilo. Por eso
	-- se espera a todas las salidas en curso (leaving), no solo a los que siguen dentro.
	game:BindToClose(function()
		SaveStore.shuttingDown()
		for _, player in Players:GetPlayers() do
			task.spawn(onRemoving, player)
		end
		local deadline = os.clock() + 25 -- Roblox da 30 s para cerrar
		while next(leaving) ~= nil and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

return SaveService
