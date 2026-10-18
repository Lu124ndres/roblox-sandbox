--!strict
--[[
	GiantPhase

	En qué fase está el gigante (comiendo, yéndose, descansando, llegando) y
	cuándo termina, publicado en EstadoGigante (Feeding/GiantPublish) para la
	cuenta regresiva de los clientes. La cambia GiantCycle por GiantService.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantPublish = require(script.Parent.GiantPublish)

local ATTR = Protocol.GiantAttributes

local GiantPhase = {}

local phase: Protocol.GiantPhase = "feeding"
local endsAt = 0

function GiantPhase.get(): Protocol.GiantPhase
	return phase
end

function GiantPhase.publish()
	GiantPublish.set(ATTR.Phase, phase)
	GiantPublish.set(ATTR.PhaseEndsAt, endsAt)
end

-- Cambia de fase; seconds = cuánto dura (para la cuenta regresiva de los clientes).
function GiantPhase.set(nextPhase: Protocol.GiantPhase, seconds: number?)
	phase = nextPhase
	endsAt = if seconds then Workspace:GetServerTimeNow() + seconds else 0
	GiantPhase.publish()
end

return GiantPhase
