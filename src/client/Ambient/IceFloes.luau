--!strict
--[[
	IceFloes

	Los témpanos del lago del zorro (IceLair): losas planas e irregulares de
	hielo (IceParts.slab), de tamaños variados.
		grandes  los de Zorro/Guarida (kind "tempano"): la cara de arriba justo en
		         Guarida.point() y plana por lo menos hasta `size` (ahí se para o se
		         echa el zorro, en las cuatro etapas). Chocan: se pisan. Debajo, un
		         faldón de hielo más hondo y azul que se ve a través del agua; al
		         borde, trozos rotos medio hundidos; arriba, parches de nieve y
		         alguna grieta.
		chicos   SMALL_COUNT témpanos sueltos que no chocan, repartidos sin pisar
		         los grandes ni las rocas (las de la orilla llegan en `avoid`).
	Los arma una vez IceLair; IceLift los sube y los hunde con el resto del lago.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guarida = require(ReplicatedStorage.Shared.Zorro.Guarida)
local IceParts = require(script.Parent.IceParts)
local LairParts = require(script.Parent.LairParts)

local I = IceParts
local TAU = math.pi * 2
local WATER = Guarida.water
local BIG_SIDES = 9
local BIG_THICK = 2.4 -- lo que asoma (Guarida: 1.2) más lo que queda abajo
local BIG_BUMPS = 0.2 -- cuánto se sale el contorno de `size`
local SKIRT_GROW = 1.08 -- el faldón bajo el agua es más ancho que la losa
local SKIRT_THICK = 4
local CHUNKS = 9 -- trozos rotos al borde de cada grande
local SNOW_LIFT = 0.25 -- la nieve queda apenas sobre el hielo (las patas se hunden)
local SMALL_COUNT = 18
local SMALL_MIN_RADIUS, SMALL_MAX_RADIUS = 26, 164
local SMALL_SIZE = NumberRange.new(4, 14)
local SMALL_GAP = 8 -- distancia mínima entre témpanos
local ROCK_FLARE = 24 -- cuánto más ancha que su cima es una roca en el agua (IceRocks)

local IceFloes = {}

local rng = Random.new(29) -- siempre los mismos témpanos

export type Placed = { at: Vector3, reach: number }

-- Parches de nieve sobre una losa: dentro de `inside` del centro y sin salirse.
-- Cada parche un poco más alto que el anterior: si se tocan, no titilan.
local function snow(parent: Instance, center: Vector3, inside: number, count: number, scale: number)
	for k = 1, count do
		local a, d = rng:NextNumber(0, TAU), inside * math.sqrt(rng:NextNumber())
		local at = center + Vector3.new(math.cos(a) * d, SNOW_LIFT + k * 0.04, math.sin(a) * d)
		local patch = I.outline(rng, scale * rng:NextNumber(0.6, 1), 0.5)
		I.slab(parent, at, patch, 6, 0.5, I.SNOW, rng, { material = Enum.Material.Snow })
	end
end

-- Una grieta: una raya fina y azul que cruza parte de la losa (sin llegar al borde).
local function crack(parent: Instance, center: Vector3, size: number)
	local a = rng:NextNumber(0, TAU)
	local from = center + Vector3.new(math.cos(a), 0, math.sin(a)) * size * rng:NextNumber(0.1, 0.3)
	local last = from + Vector3.new(0, 0.03, 0)
	for _ = 1, 3 do
		a += rng:NextNumber(-0.6, 0.6)
		local step = Vector3.new(math.cos(a), 0, math.sin(a)) * size * rng:NextNumber(0.1, 0.18)
		local nextPoint = last + step
		LairParts.bar(
			parent,
			last,
			nextPoint,
			0.35,
			0.1,
			I.ICE_DEEP,
			{ material = Enum.Material.Glacier }
		)
		last = nextPoint
	end
end

-- Trozos rotos apoyados contra el borde, por fuera de la parte que se pisa.
local function chunks(parent: Instance, center: Vector3, edge: IceParts.Edge)
	local first = rng:NextNumber(0, TAU)
	for k = 1, CHUNKS do
		local a = first + (k + rng:NextNumber(-0.35, 0.35)) / CHUNKS * TAU
		local size =
			Vector3.new(rng:NextNumber(3, 7), rng:NextNumber(1.2, 2.6), rng:NextNumber(4, 9))
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local at = Vector3.new(center.X, WATER, center.Z) + out * (edge(a) + size.Z * 0.25)
		local frame = CFrame.lookAt(at, at + out)
			* CFrame.Angles(
				rng:NextNumber(0.15, 0.5),
				rng:NextNumber(-0.4, 0.4),
				rng:NextNumber(-0.3, 0.3)
			)
		I.block(parent, size, frame, if k % 3 == 0 then I.ICE else I.ICE_EDGE)
	end
end

local function big(parent: Instance, spot: Guarida.Spot): Placed
	local top = Guarida.point(spot)
	local edge = I.outline(rng, spot.size, BIG_BUMPS)
	I.slab(parent, top, edge, BIG_SIDES, BIG_THICK, I.ICE, rng, { collide = true })
	local function skirt(a: number): number
		return edge(a) * SKIRT_GROW
	end
	local below = top - Vector3.new(0, BIG_THICK - 0.2, 0)
	I.slab(parent, below, skirt, BIG_SIDES, SKIRT_THICK, I.ICE_DEEP, rng, {
		material = Enum.Material.Glacier,
	})
	chunks(parent, top, edge)
	snow(parent, top, spot.size * 0.4, 3, spot.size * 0.3)
	for _ = 1, 2 do
		crack(parent, top, spot.size)
	end
	return { at = top, reach = spot.size * (1.15 + BIG_BUMPS * 1.1) * SKIRT_GROW * 1.05 }
end

local function free(at: Vector3, reach: number, placed: { Placed }): boolean
	for _, other in placed do
		local d = Vector3.new(at.X - other.at.X, 0, at.Z - other.at.Z).Magnitude
		if d < reach + other.reach + SMALL_GAP then
			return false
		end
	end
	return true
end

local function small(parent: Instance, placed: { Placed })
	for _ = 1, 40 do -- intentos hasta encontrar un hueco
		local size = rng:NextNumber(SMALL_SIZE.Min, SMALL_SIZE.Max)
		local reach = size * 1.7 -- lo más afuera que llega su contorno
		local a = rng:NextNumber(0, TAU)
		local r = rng:NextNumber(SMALL_MIN_RADIUS, SMALL_MAX_RADIUS - reach)
		local at = LairParts.at(a, r, WATER + rng:NextNumber(0.35, 0.8))
		if free(at, reach, placed) then
			table.insert(placed, { at = at, reach = reach })
			local edge = I.outline(rng, size, 0.45)
			I.slab(parent, at, edge, rng:NextInteger(5, 7), 1.6, I.ICE, rng)
			if rng:NextNumber() < 0.5 then
				snow(parent, at, size * 0.35, 1, size * 0.35)
			end
			return
		end
	end
end

-- avoid: lo que ya ocupa el lago (las rocas de la orilla), para no poner témpanos encima.
function IceFloes.build(parent: Instance, avoid: { Placed })
	local placed: { Placed } = table.clone(avoid)
	for _, spot in Guarida.spots do
		if spot.kind == "tempano" then
			table.insert(placed, big(parent, spot))
		else
			table.insert(placed, { at = Guarida.point(spot), reach = spot.size + ROCK_FLARE })
		end
	end
	for _ = 1, SMALL_COUNT do
		small(parent, placed)
	end
end

return table.freeze(IceFloes)
