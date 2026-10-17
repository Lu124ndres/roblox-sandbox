--!strict
--[[
	LairRocks

	Las rocas donde se posa el dragón (Dragon/Guarida.perches): peñones de
	bloques volcánicos torcidos (LairCrag). La cima son lajas en escalones, la
	primera justo en Guarida.point() (ahí apoya las patas), sobre un núcleo de
	radio `size`; abajo, una corona de bloques, laderas que se abren hacia la
	lava, taludes, bloques sueltos y costra. Por las grietas baja magma y crecen
	cristales de fuego. Nada sobresale de la cima salvo el nido (LairNest).
	Las arma una vez LavaLair, que las sube y las hunde con la lava.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local LairCrag = require(script.Parent.LairCrag)
local LairCrystals = require(script.Parent.LairCrystals)
local LairParts = require(script.Parent.LairParts)

local P = LairParts
local C = LairCrag
local TAU = math.pi * 2
local LAVA = Guarida.lava
local BELOW = 14 -- studs que la roca sigue bajo la lava
local CAP = 3 -- grosor de las lajas de la cima
local LAYER = 7 -- alto de cada hilera de la ladera
local FLARE = 7 -- cuánto más ancha es la roca en la lava que arriba
local CRUST = Color3.fromRGB(84, 38, 28)

local LairRocks = {}

local rng = Random.new(17) -- siempre las mismas rocas

-- Punto a `radius` del eje de la roca, en la dirección `angle`, a la altura y.
local function around(top: Vector3, angle: number, radius: number, y: number): (Vector3, Vector3)
	local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
	return Vector3.new(top.X, y, top.Z) + out * radius, out
end

-- Calor de la roca a la altura y: 0 en la cima, 1 en la lava.
local function heat(top: Vector3, y: number): number
	return math.clamp((top.Y - y) / (top.Y - LAVA), 0, 1) ^ 2
end

-- El contorno de la roca: a qué distancia del eje está el borde en cada dirección.
-- Con bultos, pero nunca más adentro que `size` (el dragón pisa plano hasta ahí).
type Edge = (angle: number) -> number

-- La cima: lajas giradas, cada una un poco más baja que la anterior, sobre un núcleo
-- que queda 3.5 más abajo (entre laja y laja se ve como una grieta, no como un disco).
local function cap(parent: Instance, top: Vector3, radius: number)
	local core = top.Y - 3.5 - (LAVA - BELOW)
	P.column(parent, Vector3.new(top.X, LAVA - BELOW, top.Z), core, radius, P.OBSIDIAN2, {
		collide = true,
	})
	for k = 1, 6 do
		local reach = if k == 1 then 0 else radius * 0.3 * rng:NextNumber()
		local size =
			Vector3.new(radius * rng:NextNumber(1.4, 1.7), CAP, radius * rng:NextNumber(1, 1.2))
		local at = around(top, rng:NextNumber(0, TAU), reach, top.Y - 0.18 * (k - 1) - CAP / 2)
		local spin = CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		C.block(parent, rng, size, CFrame.new(at) * spin, 0)
	end
end

-- El borde: una corona de bloques justo debajo de la cima, recostados hacia atrás.
local function rim(parent: Instance, top: Vector3, radius: number, edge: Edge)
	local count = math.max(10, math.round(TAU * radius / 9))
	for i = 1, count do
		local a = (i + rng:NextNumber(-0.3, 0.3)) / count * TAU
		local size = Vector3.new(rng:NextNumber(8, 12), rng:NextNumber(5, 9), rng:NextNumber(6, 9))
		local at, out = around(top, a, edge(a) - size.Z * 0.15, top.Y)
		local frame = C.facing(rng, at, out, rng:NextNumber(0.1, 0.45))
		local ceiling = top.Y - rng:NextNumber(0.4, 3.5)
		C.block(parent, rng, size, C.under(frame, size, ceiling), heat(top, ceiling))
	end
end

-- Las laderas: hileras de bloques, cada una más abierta que la de arriba.
local function slope(parent: Instance, top: Vector3, radius: number, edge: Edge)
	local y = top.Y - 5
	while y > LAVA - 4 do
		local flare = 1 + (top.Y - y) / (top.Y - LAVA) * FLARE
		local count = math.max(8, math.round(TAU * (radius + flare) / 11))
		local shift = rng:NextNumber(0, 1)
		for i = 1, count do
			local a = (i + shift + rng:NextNumber(-0.25, 0.25)) / count * TAU
			local size = Vector3.new(
				rng:NextNumber(10, 15),
				rng:NextNumber(LAYER, LAYER * 1.6),
				rng:NextNumber(7, 11)
			)
			local depth = edge(a) + flare - size.Z * 0.3 + rng:NextNumber(-1.5, 1.5)
			local at, out = around(top, a, depth, y - size.Y / 2 + rng:NextNumber(-1, 1))
			local frame = C.facing(rng, at, out, rng:NextNumber(0.05, 0.35))
			C.block(parent, rng, size, frame, heat(top, at.Y))
		end
		y -= LAYER
	end
end

-- Veta de magma que baja zigzagueando por una grieta de la ladera hasta la lava.
local function vein(parent: Instance, top: Vector3, edge: Edge, angle: number)
	local last = around(top, angle, edge(angle) + 0.5, top.Y - 2)
	for k = 1, 4 do
		local y = top.Y - 2 - (top.Y - 2 - LAVA) * k / 4
		local a = angle + rng:NextNumber(-0.06, 0.06)
		local ring = edge(a) + 1.5 + (top.Y - y) / (top.Y - LAVA) * FLARE
		local nextPoint = around(top, a, ring, y)
		P.bar(parent, last, nextPoint, 1.5 - k * 0.2, 1, P.MAGMA, { material = Enum.Material.Neon })
		last = nextPoint
	end
end

-- El pie: taludes en cuña medio hundidos, bloques sueltos y costra agrietada.
local function foot(parent: Instance, top: Vector3, edge: Edge)
	for i = 1, 5 do
		local a = (i + rng:NextNumber(-0.3, 0.3)) / 5 * TAU
		local size =
			Vector3.new(rng:NextNumber(10, 16), rng:NextNumber(8, 14), rng:NextNumber(10, 16))
		local at, out = around(top, a, edge(a) + FLARE + size.Z * 0.2, LAVA + size.Y * 0.1)
		local frame = CFrame.lookAt(at, at + out) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0)
		C.wedge(parent, rng, size, frame, 1)
	end
	for _ = 1, 4 do
		local s = rng:NextNumber(4, 8)
		local a = rng:NextNumber(0, TAU)
		local at = around(top, a, edge(a) + FLARE + rng:NextNumber(4, 9), LAVA)
		local tilt = CFrame.Angles(
			rng:NextNumber(-0.6, 0.6),
			rng:NextNumber(0, TAU),
			rng:NextNumber(-0.6, 0.6)
		)
		C.block(parent, rng, Vector3.new(s, s * 0.7, s * 1.2), CFrame.new(at) * tilt, 1)
	end
	-- La costra: discos corridos hacia el borde, uno por lado, así el contorno sale con
	-- bultos y entrantes en lugar de un círculo.
	local first = rng:NextNumber(0, TAU)
	for k = 1, 7 do
		local a = first + (k + rng:NextNumber(-0.2, 0.2)) / 7 * TAU
		local at = around(top, a, edge(a) * 0.55, LAVA - 0.8 + k * 0.04)
		local reach = edge(a) * 0.6 + FLARE + rng:NextNumber(1, 7)
		P.column(parent, at, 1.2, reach, CRUST, { material = Enum.Material.CrackedLava })
	end
end

local function rock(parent: Instance, perch: Guarida.Perch)
	local top = Guarida.point(perch)
	local radius = perch.size
	local p1, p2 = rng:NextNumber(0, TAU), rng:NextNumber(0, TAU)
	local function edge(a: number): number
		return radius * (1.1 + 0.08 * math.sin(2 * a + p1) + 0.06 * math.sin(3 * a + p2))
	end
	cap(parent, top, radius)
	rim(parent, top, radius, edge)
	slope(parent, top, radius, edge)
	local first = rng:NextNumber(0, TAU)
	local veins = if radius > 30 then 3 else 2
	for k = 1, veins do
		vein(parent, top, edge, first + k / veins * TAU)
	end
	for k = 1, if radius > 30 then 2 else 1 do
		-- A media ladera, sobre la lava: el eje del racimo sale hacia afuera y arriba.
		local a = first + (k + 0.5) / veins * TAU
		local y = LAVA + (top.Y - LAVA) * 0.45
		local at, out = around(top, a, edge(a) + 2 + FLARE * 0.5, y)
		local base = CFrame.lookAt(at, at + out) * CFrame.Angles(math.rad(-55), 0, 0)
		LairCrystals.cluster(parent, base, rng:NextNumber(0.8, 1))
	end
	foot(parent, top, edge)
end

function LairRocks.build(parent: Instance)
	for _, perch in Guarida.perches do
		rock(parent, perch)
	end
end

return table.freeze(LairRocks)
