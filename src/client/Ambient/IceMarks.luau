--!strict
--[[
	IceMarks

	Lo que va encima del hielo de los témpanos (IceFloes), sin chocar:
		snow(parent, rng, seed, center, inside, count, scale)
		                     `count` parches de nieve chuecos (IceShards, seeds
		                     seed + 1...) dentro de `inside` del centro, de unos
		                     `scale` de radio. Cada uno un poco más alto que el
		                     anterior: si se tocan, no titilan.
		crack(parent, rng, from, angle, size, steps)
		                     una grieta: una raya fina y azul que zigzaguea
		                     `steps` tramos desde `from`, hacia `angle`.
]]

local IceParts = require(script.Parent.IceParts)
local IcePolygon = require(script.Parent.IcePolygon)
local IceShards = require(script.Parent.IceShards)
local LairParts = require(script.Parent.LairParts)

local TAU = math.pi * 2
local around = IcePolygon.around
local PATCH: IceShards.Spec = { sides = 5, low = 0.7, high = 1.25, stretch = 0.5, bites = 0 }
local SNOW_LIFT = 0.25 -- la nieve queda apenas sobre el hielo (las patas se hunden)
local SNOW_STEP = 0.04
local SNOW_THICK = 0.5
local SNOW_LOOK = { material = Enum.Material.Snow }
local GROOVE = { material = Enum.Material.Glacier }

local IceMarks = {}

function IceMarks.snow(
	parent: Instance,
	rng: Random,
	seed: number,
	center: Vector3,
	inside: number,
	count: number,
	scale: number
)
	for k = 1, count do
		local a, d = rng:NextNumber(0, TAU), inside * math.sqrt(rng:NextNumber())
		local at = center + around(a) * d + Vector3.new(0, SNOW_LIFT + k * SNOW_STEP, 0)
		local patch = IceShards.shape(seed + k, scale * rng:NextNumber(0.6, 1), PATCH)
		IceParts.fan(parent, at, patch.corners, SNOW_THICK, IceParts.SNOW, SNOW_LOOK)
	end
end

function IceMarks.crack(
	parent: Instance,
	rng: Random,
	from: Vector3,
	angle: number,
	size: number,
	steps: number
)
	local last = from + Vector3.new(0, 0.03, 0)
	for _ = 1, steps do
		angle += rng:NextNumber(-0.6, 0.6)
		local nextPoint = last + around(angle) * size * rng:NextNumber(0.1, 0.18)
		LairParts.bar(parent, last, nextPoint, 0.35, 0.1, IceParts.ICE_DEEP, GROOVE)
		last = nextPoint
	end
end

return table.freeze(IceMarks)
