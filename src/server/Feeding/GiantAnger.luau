--!strict
--[[
	GiantAnger

	Enojo del gigante actual (0..1) y cuándo comió por última vez. GiantMood
	decide cuánto enojo toca; aquí solo se guarda y se publica (atributo
	Anger de EstadoGigante). GiantService lo expone con sus mismos nombres.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantPublish = require(script.Parent.GiantPublish)

local GiantAnger = {}

local anger = 0
local lastFedAt = os.clock()

function GiantAnger.get(): number
	return anger
end

function GiantAnger.set(value: number)
	value = math.clamp(value, 0, 1)
	if value ~= anger then
		anger = value
		GiantPublish.set(Protocol.GiantAttributes.Anger, anger)
	end
end

-- Comió (o no hay a quién atacar): enojo a cero y la cuenta empieza de nuevo.
function GiantAnger.calm()
	lastFedAt = os.clock()
	GiantAnger.set(0)
end

function GiantAnger.secondsSinceFed(): number
	return os.clock() - lastFedAt
end

return GiantAnger
