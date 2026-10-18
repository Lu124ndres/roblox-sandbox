--!strict
--[[
	IceRocks

	Peñones de roca fría con nieve para el hábitat del zorro (IceLair): la roca de
	vigía de Zorro/Guarida (kind "roca", que choca: ahí se sienta) y las rocas de
	la orilla (IceShore, que no chocan). Se arman como las de la guarida volcánica
	(LairRocks), con piedra gris azulada en vez de basalto:
		cima     lajas giradas en escalones; la primera con la cara de arriba
		         justo en `top` (ahí apoya las patas), sobre un núcleo escondido;
		         parches de nieve encima
		corona   bloques bajados con LairCrag.under (nada sobresale de la cima),
		         la mitad con un copete de nieve
		laderas  hileras de bloques torcidos que se abren hacia el agua; abajo,
		         la piedra está escarchada
		racimos  cristales de hielo (IceCrystals) a media ladera, hacia afuera
		collar   costra de hielo a ras del agua en tramos corridos (no un anillo)
	El contorno tiene bultos, pero nunca más adentro que `size`.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guarida = require(ReplicatedStorage.Shared.Zorro.Guarida)
local IceCrystals = require(script.Parent.IceCrystals)
local IceParts = require(script.Parent.IceParts)
local LairCrag = require(script.Parent.LairCrag)
local LairParts = require(script.Parent.LairParts)

local I = IceParts
local TAU = math.pi * 2
local WATER = Guarida.water
local BELOW = 13 -- studs que la roca sigue bajo el agua (más abajo la tapa el abismo)
local CAP = 3 -- grosor de las lajas de la cima
local LAYER = 6 -- alto de cada hilera de la ladera
local FLARE = 8 -- cuánto más ancha es la roca en el agua que arriba
local SNOWY = 0.5 -- parte de los bloques de la corona con nieve encima
local FROST_BAND = 4 -- studs sobre el agua donde la piedra está escarchada
local MATERIALS = { Enum.Material.Slate, Enum.Material.Slate, Enum.Material.Rock }

local IceRocks = {}

export type Edge = (angle: number) -> number

local function around(top: Vector3, angle: number, radius: number, y: number): (Vector3, Vector3)
	local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
	return Vector3.new(top.X, y, top.Z) + out * radius, out
end

local function stone(
	parent: Instance,
	rng: Random,
	size: Vector3,
	cframe: CFrame,
	collide: boolean
): BasePart
	local color = I.ROCKS[rng:NextInteger(1, #I.ROCKS)]
	if cframe.Position.Y < WATER + FROST_BAND then
		color = color:Lerp(I.FROST, 0.35)
	end
	return LairParts.part(parent, size, cframe, color, {
		material = MATERIALS[rng:NextInteger(1, #MATERIALS)],
		collide = collide,
	})
end

local function cap(parent: Instance, rng: Random, top: Vector3, radius: number, collide: boolean)
	local bottom = WATER - BELOW
	local core = LairParts.column(
		parent,
		Vector3.new(top.X, bottom, top.Z),
		top.Y - 3.5 - bottom,
		radius,
		I.ROCKS[3],
		{ collide = collide, material = Enum.Material.Slate }
	)
	core.CastShadow = false
	for k = 1, 5 do
		local reach = if k == 1 then 0 else radius * 0.3 * rng:NextNumber()
		local size =
			Vector3.new(radius * rng:NextNumber(1.4, 1.7), CAP, radius * rng:NextNumber(1, 1.2))
		local at = around(top, rng:NextNumber(0, TAU), reach, top.Y - 0.18 * (k - 1) - CAP / 2)
		stone(
			parent,
			rng,
			size,
			CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			collide
		)
	end
	for k = 1, 2 do
		local a, d = rng:NextNumber(0, TAU), radius * 0.45 * rng:NextNumber()
		local at = around(top, a, d, top.Y + 0.25 + k * 0.04)
		local patch = I.outline(rng, radius * rng:NextNumber(0.25, 0.4), 0.5)
		I.slab(parent, at, patch, 6, 0.5, I.SNOW, rng, { material = Enum.Material.Snow })
	end
end

local function rim(parent: Instance, rng: Random, top: Vector3, radius: number, edge: Edge)
	local count = math.max(9, math.round(TAU * radius / 9))
	for i = 1, count do
		local a = (i + rng:NextNumber(-0.3, 0.3)) / count * TAU
		local size = Vector3.new(rng:NextNumber(7, 11), rng:NextNumber(4, 8), rng:NextNumber(5, 8))
		local at, out = around(top, a, edge(a) - size.Z * 0.15, top.Y)
		local frame = LairCrag.facing(rng, at, out, rng:NextNumber(0.1, 0.45))
		frame = LairCrag.under(frame, size, top.Y - rng:NextNumber(0.9, 3.5))
		stone(parent, rng, size, frame, false)
		if rng:NextNumber() < SNOWY then
			local cover = Vector3.new(size.X * 0.85, 0.45, size.Z * 0.85)
			I.block(parent, cover, frame * CFrame.new(0, size.Y / 2 + 0.15, 0), I.SNOW, {
				material = Enum.Material.Snow,
			})
		end
	end
end

local function slope(parent: Instance, rng: Random, top: Vector3, radius: number, edge: Edge)
	local y = top.Y - 4
	local bottom = WATER - BELOW
	while y > bottom + 2 do
		local flare = 1 + (top.Y - y) / (top.Y - bottom) * FLARE
		local count = math.max(7, math.round(TAU * (radius + flare) / 10))
		local shift = rng:NextNumber(0, 1)
		for i = 1, count do
			local a = (i + shift + rng:NextNumber(-0.25, 0.25)) / count * TAU
			local size = Vector3.new(
				rng:NextNumber(9, 14),
				rng:NextNumber(LAYER, LAYER * 1.6),
				rng:NextNumber(6, 10)
			)
			local depth = edge(a) + flare - size.Z * 0.3 + rng:NextNumber(-1.5, 1.5)
			local at, out = around(top, a, depth, y - size.Y / 2 + rng:NextNumber(-1, 1))
			stone(
				parent,
				rng,
				size,
				LairCrag.facing(rng, at, out, rng:NextNumber(0.05, 0.35)),
				false
			)
		end
		y -= LAYER
	end
end

-- La costra de hielo a ras del agua: losas corridas, una por lado y a distinta altura.
local function collar(parent: Instance, rng: Random, top: Vector3, edge: Edge)
	local first = rng:NextNumber(0, TAU)
	local pieces = rng:NextInteger(4, 6)
	for k = 1, pieces do
		local a = first + (k + rng:NextNumber(-0.25, 0.25)) / pieces * TAU
		local at = around(top, a, edge(a) + FLARE * 0.7, WATER + 0.2 + k * 0.04)
		local patch = I.outline(rng, rng:NextNumber(4, 8), 0.6)
		I.slab(parent, at, patch, 6, 0.8, I.ICE_EDGE, rng)
	end
end

-- Una roca con la cima en `top` y plana hasta `size`. collide: se pisa la cima.
function IceRocks.rock(parent: Instance, rng: Random, top: Vector3, size: number, collide: boolean)
	local p1, p2 = rng:NextNumber(0, TAU), rng:NextNumber(0, TAU)
	local function edge(a: number): number
		return size * (1.1 + 0.08 * math.sin(2 * a + p1) + 0.06 * math.sin(3 * a + p2))
	end
	cap(parent, rng, top, size, collide)
	rim(parent, rng, top, size, edge)
	slope(parent, rng, top, size, edge)
	local first = rng:NextNumber(0, TAU)
	local clusters = if size > 18 then 3 else 1
	for k = 1, clusters do
		local a = first + k / clusters * TAU
		local y = WATER + (top.Y - WATER) * 0.5
		local at, out = around(top, a, edge(a) + 1 + FLARE * 0.4, y)
		local base = CFrame.lookAt(at, at + out) * CFrame.Angles(math.rad(-55), 0, 0)
		IceCrystals.cluster(
			parent,
			rng,
			base,
			rng:NextNumber(0.7, 1) * math.clamp(size / 20, 0.6, 1.3)
		)
	end
	collar(parent, rng, top, edge)
end

-- Las rocas de Zorro/Guarida (la de vigía): chocan.
function IceRocks.build(parent: Instance)
	local rng = Random.new(53) -- siempre las mismas rocas
	for _, spot in Guarida.spots do
		if spot.kind == "roca" then
			IceRocks.rock(parent, rng, Guarida.point(spot), spot.size, true)
		end
	end
end

return table.freeze(IceRocks)
