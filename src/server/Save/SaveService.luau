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
		- Al salir: guarda y suelta el bloqueo.
		- Al cerrar el servidor (BindToClose): guarda a todos a la vez y
		  espera a que terminen.
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

local SaveService = {}

local saving: { [Player]: boolean } = {} -- evita dos guardados del mismo jugador a la vez

local function load(player: Player)
	PlayerData.prepare(player)
	for _ = 1, SAVING.lockedRetries do
		local status, data = SaveStore.acquire(player.UserId)
		if not player.Parent then
			if status == "ok" and data then
				SaveStore.write(player.UserId, data, true) -- se fue mientras cargaba: soltar
			end
			return
		end
		if status == "ok" and data then
			PlayerData.attach(player, data)
			return
		elseif status == "error" then
			player:Kick(ERROR_MESSAGE)
			return
		end
		task.wait(SAVING.lockedRetrySeconds)
	end
	player:Kick(LOCKED_MESSAGE)
end

local function save(player: Player, release: boolean): boolean
	if saving[player] then
		return false
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
	-- Espera un guardado automático en curso para no soltar el bloqueo antes de tiempo.
	while saving[player] do
		task.wait(0.1)
	end
	save(player, true)
	PlayerData.detach(player)
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

	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				onRemoving(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25 -- Roblox da 30 s para cerrar
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

return SaveService
