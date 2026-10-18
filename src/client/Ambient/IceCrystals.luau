--!strict
--[[
	IceCrystals

	Racimos de cristales de hielo para las rocas y el acantilado del hábitat del
	zorro (IceLair). Cada cristal es un prisma de sección rombo con la punta en
	cuña (dos cuñas espalda con espalda, como un cincel), inclinado hacia afuera;
	al pie, esquirlas sueltas en cuña y un poco de nieve. El del medio lleva una
	veta de brillo adentro y una luz fría suave. Nada de cilindros.
		cluster(parent, rng, base, scale)   base: su eje Y es hacia donde crecen
]]

local IceParts = require(script.Parent.IceParts)
local LairParts = require(script.Parent.LairParts)

local I = IceParts
local COLORS = { I.CRYSTAL, I.CRYSTAL_DEEP, I.CRYSTAL_LIGHT }
local CLEAR = 0.12 -- transparencia del hielo de los cristales
local AROUND = 5 -- cristales alrededor del del medio
local SHARDS = 3 -- esquirlas tiradas al pie
local LIGHT_BRIGHTNESS = 0.8
local LIGHT_RANGE = 14 -- a escala 1

local IceCrystals = {}

-- Un cristal: cuerpo de rombo (ancho x alto x hondo) y la punta en cincel.
local function prism(
	parent: Instance,
	base: CFrame,
	width: number,
	height: number,
	color: Color3
): Part
	local body = height * 0.76
	local tip = height - body
	local axis = base * CFrame.Angles(0, math.rad(45), 0)
	local depth = width * 0.8
	local options = { transparency = CLEAR }
	local part = I.block(
		parent,
		Vector3.new(width, body, depth),
		axis * CFrame.new(0, body / 2, 0),
		color,
		options
	)
	local half = Vector3.new(width, tip, depth / 2)
	I.wedge(parent, half, axis * CFrame.new(0, body + tip / 2, -depth / 4), color, options)
	I.wedge(
		parent,
		half,
		axis * CFrame.new(0, body + tip / 2, depth / 4) * CFrame.Angles(0, math.pi, 0),
		color,
		options
	)
	return part
end

function IceCrystals.cluster(parent: Instance, rng: Random, base: CFrame, scale: number)
	local middle = prism(parent, base, 1.8 * scale, 10 * scale, I.CRYSTAL)
	-- La veta de brillo, adentro del cristal del medio.
	LairParts.part(
		parent,
		Vector3.new(0.5, 6, 0.5) * scale,
		base * CFrame.new(0, 4 * scale, 0),
		I.GLOW,
		{ material = Enum.Material.Neon, transparency = 0.45 }
	)
	LairParts.light(middle, I.GLOW, LIGHT_BRIGHTNESS, LIGHT_RANGE * scale)
	for k = 1, AROUND do
		local around = k / AROUND * math.pi * 2 + rng:NextNumber(-0.35, 0.35)
		local tilt = math.rad(rng:NextNumber(16, 42))
		local at = base
			* CFrame.Angles(0, around, 0)
			* CFrame.new(0, 0, -1.5 * scale)
			* CFrame.Angles(-tilt, rng:NextNumber(0, math.pi), 0)
		prism(
			parent,
			at,
			rng:NextNumber(0.9, 1.4) * scale,
			rng:NextNumber(3.5, 7.5) * scale,
			COLORS[rng:NextInteger(1, #COLORS)]
		)
	end
	for _ = 1, SHARDS do
		local around = rng:NextNumber(0, math.pi * 2)
		local size = Vector3.new(0.8, rng:NextNumber(1, 2), rng:NextNumber(1.6, 2.6)) * scale
		local at = base
			* CFrame.Angles(0, around, 0)
			* CFrame.new(0, size.Y * 0.3, -3.2 * scale)
			* CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.5, 0.5))
		I.wedge(parent, size, at, COLORS[rng:NextInteger(1, #COLORS)], { transparency = CLEAR })
	end
	-- Pie: un montoncito de nieve donde nacen.
	I.block(
		parent,
		Vector3.new(5, 1.2, 4.4) * scale,
		base * CFrame.new(0, 0.1 * scale, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
		I.SNOW,
		{ material = Enum.Material.Snow }
	)
end

return table.freeze(IceCrystals)
