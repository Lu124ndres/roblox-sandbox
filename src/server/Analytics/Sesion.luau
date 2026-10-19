--!strict
--[[
	Analytics/Sesion

	Lo que pasa en una sesión de un jugador, de que cargan sus datos a que sale:
		- al salir manda cuánto jugó, sus kills, peces pescados y entregados, peces
		  por minuto y la rareza más alta, con el monstruo y la etapa del momento,
		  la fase del ciclo y dónde estaba (cráter, estanques o isla): para ver en
		  qué momento abandonan;
		- cada minuto suma uno a playMinutes (el tiempo total, que se guarda);
		- cada FLUSH_MINUTES y al salir vacía la economía (Analytics/Economia).
	Guarda una referencia a los datos del jugador al empezar: al salir puede que
	SaveService ya los haya soltado de PlayerData.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local PlayerData = require(script.Parent.Parent.PlayerData)
local SaveSchema = require(script.Parent.Parent.Save.SaveSchema)
local Economia = require(script.Parent.Economia)
local Envio = require(script.Parent.Envio)

local TICK_SECONDS = 60 -- playMinutes sube de a uno
local FLUSH_MINUTES = 10 -- la economía se manda cada tanto, no por pez
local GIANT = Protocol.GiantAttributes

type Session = {
	save: SaveSchema.SaveData,
	startedAt: number,
	caught: number,
	delivered: number,
	kills: number,
	rarity: number, -- índice de la rareza más alta que sacó
	rarityId: string,
}

local Sesion = {}

local sessions: { [Player]: Session } = {}

function Sesion.start(player: Player, save: SaveSchema.SaveData)
	sessions[player] = {
		save = save,
		startedAt = os.clock(),
		caught = save.stats.fishCaught,
		delivered = save.stats.fishDelivered,
		kills = save.kills,
		rarity = 0,
		rarityId = "ninguna",
	}
end

function Sesion.catch(player: Player, fishId: string)
	local session = sessions[player]
	if not session then
		return
	end
	local rarity, index = FishCatalog.rarity(fishId)
	if index > session.rarity then
		session.rarity, session.rarityId = index, rarity.id
	end
end

-- Minutos de esta sesión (0 si no empezó).
function Sesion.minutes(player: Player): number
	local session = sessions[player]
	return if session then (os.clock() - session.startedAt) / 60 else 0
end

-- "Orca:2", la fase del ciclo y la zona del jugador, para los campos de los eventos.
local function context(player: Player): { string }
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local id = state and state:GetAttribute(GIANT.Id)
	local progress = state and state:GetAttribute(GIANT.Progress)
	local phase = state and state:GetAttribute(GIANT.Phase)
	local stage = GiantStages.stageFor(if type(progress) == "number" then progress else 0)
	local zone = "isla"
	local pond = player:GetAttribute(Protocol.PlayerAttributes.TrainingPond)
	local character = player.Character
	if type(pond) == "number" and pond > 0 then
		zone = "estanques"
	elseif character and WorldZones.craterBlend(character:GetPivot().Position) > 0.5 then
		zone = "crater"
	end
	return {
		`{if type(id) == "string" then id else "?"}:{stage}`,
		if type(phase) == "string" then phase else "?",
		zone,
	}
end

function Sesion.finish(player: Player)
	local session = sessions[player]
	sessions[player] = nil
	if not session then
		return
	end
	local save = session.save
	local minutes = (os.clock() - session.startedAt) / 60
	local caught = save.stats.fishCaught - session.caught
	Envio.custom(player, "SesionMinutos", math.round(minutes * 10) / 10, context(player))
	Envio.custom(player, "SesionKills", save.kills - session.kills)
	Envio.custom(player, "SesionPeces", caught, { session.rarityId })
	Envio.custom(player, "SesionEntregados", save.stats.fishDelivered - session.delivered)
	if minutes >= 1 then
		Envio.custom(player, "SesionPecesPorMinuto", math.round(caught / minutes * 10) / 10)
	end
	Economia.flush(player, save.coins)
end

function Sesion.init()
	task.spawn(function()
		local ticks = 0
		while true do
			task.wait(TICK_SECONDS)
			ticks += 1
			for player, session in sessions do
				if player.Parent == Players then
					PlayerData.edit(player, function(data)
						data.playMinutes += 1
					end)
					if ticks % FLUSH_MINUTES == 0 then
						Economia.flush(player, session.save.coins)
					end
				end
			end
		end
	end)
end

return Sesion
