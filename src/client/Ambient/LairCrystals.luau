--!strict
--[[
	LairCrystals

	Cristales de fuego de la guarida volcánica: racimos de prismas de neón
	(naranja, rojo y amarillo) que salen inclinados de la roca, con una luz
	que late. cluster() arma uno en cualquier lugar (las rocas donde se posa
	el dragón llevan algunos en las laderas) y build() reparte los de la
	repisa del cráter, entre los props del hábitat y las cascadas.
]]

local LairParts = require(script.Parent.LairParts)

local P = LairParts
local COLORS = { P.MAGMA, P.MAGMA_HOT, P.EMBER }
-- En la repisa: ángulo (grados) y radio, sin pisar los props (Config.Habitats) ni las cascadas.
local SHELF = { { 45, 182 }, { 112, 184 }, { 165, 183 }, { 288, 183 }, { 322, 184 }, { 352, 184 } }

local LairCrystals = {}

local rng = Random.new(41) -- siempre la misma guarida

-- Un prisma: cuerpo de sección rombo y una punta más fina arriba.
local function prism(
	parent: Instance,
	base: CFrame,
	width: number,
	height: number,
	color: Color3
): Part
	local turn = CFrame.Angles(0, math.rad(45), 0)
	local body = P.part(
		parent,
		Vector3.new(width, height * 0.75, width),
		base * CFrame.new(0, height * 0.375, 0) * turn,
		color,
		{ material = Enum.Material.Neon, transparency = 0.08 }
	)
	P.part(
		parent,
		Vector3.new(width * 0.55, height * 0.3, width * 0.55),
		base * CFrame.new(0, height * 0.85, 0) * turn,
		color,
		{ material = Enum.Material.Neon, transparency = 0.15 }
	)
	return body
end

-- Racimo con su base en `base` (su eje Y es hacia donde crecen). Devuelve el del medio.
function LairCrystals.cluster(parent: Instance, base: CFrame, scale: number): Part
	local middle = prism(parent, base, 1.6 * scale, 9 * scale, P.MAGMA_HOT)
	for k = 1, 5 do
		local around = k / 5 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local tilt = math.rad(rng:NextNumber(18, 38))
		local at = base
			* CFrame.Angles(0, around, 0)
			* CFrame.new(0, 0, -1.4 * scale)
			* CFrame.Angles(-tilt, 0, 0)
		local height = rng:NextNumber(3.5, 6.5) * scale
		prism(
			parent,
			at,
			rng:NextNumber(0.9, 1.3) * scale,
			height,
			COLORS[rng:NextInteger(1, #COLORS)]
		)
	end
	-- Pie de roca oscura donde nacen.
	P.part(
		parent,
		Vector3.new(4.6, 1.6, 4.2) * scale,
		base * CFrame.new(0, 0.2 * scale, 0),
		P.OBSIDIAN,
		{ material = Enum.Material.Basalt }
	)
	local light = P.light(middle, P.MAGMA, 1.6, 12 * scale)
	P.pulse(light, { Brightness = 0.5 }, rng:NextNumber(1.8, 2.8))
	P.pulse(middle, { Transparency = 0.45 }, rng:NextNumber(1.8, 2.8))
	return middle
end

-- Los racimos de la repisa (fijos: la repisa queda sobre la lava).
function LairCrystals.build(parent: Instance)
	for _, spot in SHELF do
		local angle, radius = math.rad(spot[1]), spot[2]
		local ground = P.ground(radius)
		local base = CFrame.new(P.at(angle, radius, ground - 0.4))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		LairCrystals.cluster(parent, base, rng:NextNumber(1.1, 1.5))
	end
end

return table.freeze(LairCrystals)
