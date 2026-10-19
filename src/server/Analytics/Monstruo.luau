--!strict
--[[
	Analytics/Monstruo

	Los eventos del monstruo (uno por monstruo, no por jugador):
		MonstruoLleno   minutos que tardó en llenarse, cuántos aportaron y cuántos
		                había en el servidor; y MonstruoComida, la comida total.
		MonstruoSeFue   se cansó sin llenarse: progreso, etapa y jugadores.
	Roblox pide un jugador para cada evento: se manda con uno de los que
	aportaron (o cualquiera del servidor). Los minutos cuentan desde que la
	fase pasó a "feeding" (lo sigue start).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Envio = require(script.Parent.Envio)

local ATTR = Protocol.GiantAttributes

local Monstruo = {}

local feedingSince = os.clock() -- cuándo empezó a comer el monstruo actual

-- Sin esperar en el hilo de quien llama: la carpeta del estado la crea GiantService.init,
-- que en Main corre después de Analytics.init.
function Monstruo.start()
	task.spawn(function()
		local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
		local phase = state:GetAttribute(ATTR.Phase)
		state:GetAttributeChangedSignal(ATTR.Phase):Connect(function()
			local now = state:GetAttribute(ATTR.Phase)
			if now == "feeding" and phase ~= "feeding" then
				feedingSince = os.clock()
			end
			phase = now
		end)
	end)
end

-- El monstruo se llenó o se fue (tired). paid: userIds de los que cobraron la kill.
function Monstruo.done(def: Config.GiantDef, tired: boolean, paid: { [number]: boolean })
	local carrier: Player? = nil
	local count = 0
	for userId in paid do
		count += 1
		carrier = carrier or Players:GetPlayerByUserId(userId)
	end
	carrier = carrier or Players:GetPlayers()[1]
	if not carrier then
		return
	end
	local players = tostring(#Players:GetPlayers())
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local rawProgress = state and state:GetAttribute(ATTR.Progress)
	local rawFood = state and state:GetAttribute(ATTR.Food)
	local progress = if type(rawProgress) == "number" then rawProgress else 0
	local food = if type(rawFood) == "number" then rawFood else 0
	if tired then
		local stage = `E{GiantStages.stageFor(progress)}`
		Envio.custom(
			carrier,
			"MonstruoSeFue",
			math.round(progress * 100),
			{ def.id, stage, players }
		)
	else
		local minutes = math.round((os.clock() - feedingSince) / 6) / 10
		Envio.custom(carrier, "MonstruoLleno", minutes, { def.id, tostring(count), players })
		Envio.custom(carrier, "MonstruoComida", food, { def.id })
	end
end

return Monstruo
