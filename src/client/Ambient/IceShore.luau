--!strict
--[[
	IceShore

	La orilla helada del cráter del zorro (IceLair):
		costra    hielo a ras del agua contra el acantilado, en tramos corridos de
		          largo distinto con huecos entre medio (no un anillo)
		escarcha  placas pegadas a la pared del acantilado, más tupidas abajo,
		          y parches de nieve cerca del borde de arriba
		racimos   cristales de hielo (IceCrystals) que salen de la pared
		rocas     peñones con nieve y cristales en la repisa (IceRocks, sin chocar)
	La pared es la de LairParts.ground (la misma curva que server/World/CraterShape).
	La puerta (por donde llega el puente) queda libre: nada tapa la vista del lago.
	build(lake, shore): las rocas van en `lake` (suben y bajan con los témpanos),
	el resto en `shore`. rocks() da dónde están, para que los témpanos no las pisen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guarida = require(ReplicatedStorage.Shared.Zorro.Guarida)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local IceCrystals = require(script.Parent.IceCrystals)
local IceParts = require(script.Parent.IceParts)
local IceRocks = require(script.Parent.IceRocks)
local LairParts = require(script.Parent.LairParts)

local I = IceParts
local P = LairParts
local L = WorldLayout
local TAU = math.pi * 2
local WATER = Guarida.water
local LAKE, CLIFF = L.craterLakeRadius, L.craterCliffRadius
local DOOR = math.rad(L.bridgeAngle + 180) -- la puerta del cráter
local DOOR_GAP = math.rad(22) -- a cada lado de la puerta no va nada alto
local RUN = NumberRange.new(math.rad(14), math.rad(42)) -- largo de cada tramo de costra
local GAP = NumberRange.new(math.rad(5), math.rad(18)) -- hueco entre tramos
local CRUST_STEP = 7 -- studs de arco por pieza de costra
local FROST_PLATES = 70
local SNOW_PLATES = 34
-- Grados, lejos de la puerta y de las cascadas de lava del mundo (cascada_lava en
-- tools/generar_isla.py: 20, 62, 108, 150, 192, 228, 318 y 345).
local CLIFF_CLUSTERS = { 40, 85, 128, 172, 210, 300, 332 }
-- Rocas de la repisa: ángulo (grados), radio, alto de la cima sobre el agua y radio.
local ROCKS = {
	{ 0, 176, 9, 10 },
	{ 40, 178, 13, 12 },
	{ 75, 180, 6, 8 },
	{ 135, 176, 8, 10 },
	{ 184, 177, 11, 10 },
	{ 300, 178, 7, 9 },
}
local ROCK_REACH = 22 -- cuánto más ancha que su cima es una roca en el agua

local IceShore = {}

local rng = Random.new(67) -- siempre la misma orilla

local function nearDoor(a: number): boolean
	return math.abs((a - DOOR + math.pi) % TAU - math.pi) < DOOR_GAP
end

-- Un punto de la pared a `r` del centro, con su normal (hacia el lago y arriba)
-- y la dirección a lo largo de la orilla.
local function wall(a: number, r: number): (Vector3, Vector3, Vector3)
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local rise = (P.ground(r + 0.25) - P.ground(r - 0.25)) / 0.5
	local normal = (Vector3.yAxis - out * rise).Unit
	local along = Vector3.new(-out.Z, 0, out.X)
	return P.at(a, r, P.ground(r)), normal, along
end

-- Una placa delgada apoyada en la pared (ancho a lo largo de la orilla, alto pared arriba).
local function plate(
	parent: Instance,
	a: number,
	r: number,
	size: Vector2,
	color: Color3,
	material: Enum.Material
)
	local at, normal, along = wall(a, r)
	local spin = CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0)
	local frame = CFrame.fromMatrix(at + normal * 0.35, along, normal) * spin
	I.block(parent, Vector3.new(size.X, 0.5, size.Y), frame, color, { material = material })
end

local function crust(parent: Instance)
	local a, k = rng:NextNumber(0, TAU), 0
	local finish = a + TAU - GAP.Max
	while a < finish do
		local run = rng:NextNumber(RUN.Min, RUN.Max)
		local pieces = math.max(1, math.floor(run * LAKE / CRUST_STEP))
		for j = 1, pieces do
			local angle = a + (j - 0.5) / pieces * run
			local across = rng:NextNumber(4, 10)
			local size = Vector3.new(rng:NextNumber(6, 11), 0.7, across)
			k += 1
			local at = P.at(angle, LAKE + 1.5 - across * 0.35, WATER + 0.12 + (k % 6) * 0.035)
			local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local frame = CFrame.lookAt(at, at + out)
				* CFrame.Angles(0, rng:NextNumber(-0.45, 0.45), 0)
			I.block(parent, size, frame, if k % 4 == 0 then I.ICE else I.ICE_EDGE)
		end
		a += run + rng:NextNumber(GAP.Min, GAP.Max)
	end
end

local function frost(parent: Instance)
	for _ = 1, FROST_PLATES do
		-- Más tupida abajo, junto al agua: el radio sale sesgado hacia el lago.
		local r = LAKE + 0.6 + (CLIFF - LAKE - 3) * rng:NextNumber() ^ 2
		local size = Vector2.new(rng:NextNumber(6, 14), rng:NextNumber(3, 7))
		local ice = rng:NextNumber() < 0.4
		plate(
			parent,
			rng:NextNumber(0, TAU),
			r,
			size,
			if ice then I.ICE_EDGE else I.FROST,
			if ice then Enum.Material.Ice else Enum.Material.Snow
		)
	end
	for _ = 1, SNOW_PLATES do
		local r = CLIFF - 1 - rng:NextNumber() * 3
		plate(
			parent,
			rng:NextNumber(0, TAU),
			r,
			Vector2.new(rng:NextNumber(7, 16), 3),
			I.SNOW,
			Enum.Material.Snow
		)
	end
end

local function clusters(parent: Instance)
	for _, degrees in CLIFF_CLUSTERS do
		local a = math.rad(degrees + rng:NextNumber(-4, 4))
		local at, normal = wall(a, LAKE + rng:NextNumber(4, 8))
		local axis = (normal + Vector3.yAxis).Unit
		local base = CFrame.lookAt(at, at + axis, normal:Cross(Vector3.yAxis))
			* CFrame.Angles(math.rad(-90), 0, 0)
		IceCrystals.cluster(parent, rng, base, rng:NextNumber(1.1, 1.5))
	end
end

-- Dónde están las rocas de la repisa (para IceFloes).
function IceShore.rocks(): { { at: Vector3, reach: number } }
	local list: { { at: Vector3, reach: number } } = {}
	for _, rock in ROCKS do
		local at = P.at(math.rad(rock[1]), rock[2], WATER + rock[3])
		table.insert(list, { at = at, reach = rock[4] + ROCK_REACH })
	end
	return list
end

function IceShore.build(lake: Instance, shore: Instance)
	for _, rock in ROCKS do
		if not nearDoor(math.rad(rock[1])) then
			IceRocks.rock(
				lake,
				rng,
				P.at(math.rad(rock[1]), rock[2], WATER + rock[3]),
				rock[4],
				false
			)
		end
	end
	crust(shore)
	frost(shore)
	clusters(shore)
end

return table.freeze(IceShore)
