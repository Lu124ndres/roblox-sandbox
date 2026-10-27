--!strict
--[[
	LairNest

	El nido del dragón sobre la roca central (Dragon/Guarida.nest): una cama
	de ceniza con brasas que laten, un borde de piedras quemadas y huesos, y
	tres huevos grandes de dragón marino (verde azulado con manchas, como
	sus escamas) con grietas de fuego que brillan y una luz adentro que late,
	como si algo se moviera. Al lado, un huevo ya abierto (la base rota de la
	cáscara, con su resplandor) y cáscaras sueltas. Lo arma una vez LavaLair
	y sube y se hunde con las rocas. Las luces de los huevos y las brasas que
	suben van aparte (`kept`): quedan también con el nido de Blender.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local LairParts = require(script.Parent.LairParts)

local P = LairParts
local rgb = Color3.fromRGB
local SHELL = { rgb(32, 128, 138), rgb(26, 104, 126), rgb(44, 150, 138) }
local SPOT_LIGHT, SPOT_DARK = rgb(120, 222, 208), rgb(16, 66, 80)
local CHAR, BONE = rgb(38, 31, 30), rgb(196, 182, 160)
local GLOW = rgb(255, 150, 60)
-- Huevos: x, z (desde el centro del nido), alto y color.
local EGGS = { { 0, 1.2, 7.6, 1 }, { 3.7, -1.2, 6.4, 2 }, { -3.6, -1.0, 6.2, 3 } }
local RIM_STONES = 14
local RIM = 8 -- radio del borde

local LairNest = {}

local rng = Random.new(23)

local function ellipsoid(parent: Instance, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = P.part(
		parent,
		size,
		cframe,
		color,
		{ material = Enum.Material.SmoothPlastic, reflectance = 0.12 }
	)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- Punto de la cáscara (y su normal) a la vuelta phi y la altura v (-1 abajo, 1 arriba).
local function surface(
	egg: CFrame,
	a: number,
	b: number,
	phi: number,
	v: number
): (Vector3, Vector3)
	local ring = a * math.sqrt(math.max(1 - v * v, 0))
	local localPoint = Vector3.new(math.cos(phi) * ring, v * b, math.sin(phi) * ring)
	local normal =
		Vector3.new(localPoint.X / (a * a), localPoint.Y / (b * b), localPoint.Z / (a * a)).Unit
	return egg * localPoint, egg:VectorToWorldSpace(normal)
end

local function egg(parent: Instance, kept: Instance, nest: Vector3, spec: { number })
	local height = spec[3]
	local a, b = height * 0.35, height * 0.5
	local tilt = CFrame.Angles(
		rng:NextNumber(-0.15, 0.15),
		rng:NextNumber(0, 6.3),
		rng:NextNumber(-0.15, 0.15)
	)
	local cframe = CFrame.new(nest + Vector3.new(spec[1], 0.6 + b * 0.9, spec[2])) * tilt
	ellipsoid(parent, Vector3.new(a * 2, b * 2, a * 2), cframe, SHELL[spec[4]])
	for k = 1, 4 do -- manchas
		local point, normal =
			surface(cframe, a, b, k * 1.7 + rng:NextNumber(0, 0.6), rng:NextNumber(-0.4, 0.6))
		local size = height * rng:NextNumber(0.12, 0.2)
		local spot = CFrame.lookAt(point - normal * 0.05, point + normal)
		ellipsoid(
			parent,
			Vector3.new(size, size * 0.7, 0.3),
			spot,
			if k % 2 == 0 then SPOT_LIGHT else SPOT_DARK
		)
	end
	for k = 1, 2 do -- grietas de fuego, en zigzag
		local phi = k * math.pi + rng:NextNumber(-0.5, 0.5)
		local last = surface(cframe, a * 1.01, b * 1.01, phi, 0.55)
		for step = 1, 3 do
			phi += rng:NextNumber(-0.35, 0.35)
			local point, normal = surface(cframe, a * 1.01, b * 1.01, phi, 0.55 - step * 0.3)
			local crack = P.bar(
				parent,
				last,
				point,
				0.22,
				0.15,
				GLOW,
				{ material = Enum.Material.Neon, up = normal }
			)
			P.pulse(crack, { Transparency = 0.7 }, 1.3 + k * 0.2)
			last = point
		end
	end
	local light = P.light(P.holder(kept, cframe), GLOW, 0.6, height * 1.4)
	P.pulse(light, { Brightness = 2.4 }, rng:NextNumber(1.4, 2))
end

-- El huevo abierto: la base rota de la cáscara, con brillo adentro.
local function hatched(parent: Instance, at: Vector3)
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local height = rng:NextNumber(1.3, 2.6)
		local base = at + out * 2.1 + Vector3.new(0, 0.6 + height / 2, 0)
		local cframe = CFrame.lookAt(base, base + out) * CFrame.Angles(math.rad(-14), 0, 0)
		P.part(parent, Vector3.new(1.9, height, 0.3), cframe, SHELL[1 + k % 3], {
			material = Enum.Material.SmoothPlastic,
		})
	end
	local glow = P.column(
		parent,
		at + Vector3.new(0, 0.6, 0),
		0.4,
		1.9,
		GLOW,
		{ material = Enum.Material.Neon }
	)
	P.pulse(glow, { Transparency = 0.5 }, 1.1)
end

function LairNest.build(parent: Instance, kept: Instance)
	local nest = Guarida.point(Guarida.perches[Guarida.nest.perch]) + Guarida.nest.offset
	-- Cama de ceniza y brasas.
	P.column(parent, nest, 0.6, RIM + 0.5, P.ASH, { material = Enum.Material.Slate })
	local embers = P.column(parent, nest + Vector3.new(0, 0.55, 0), 0.15, RIM - 2.5, P.MAGMA, {
		material = Enum.Material.Neon,
		transparency = 0.3,
	})
	P.pulse(embers, { Transparency = 0.75 }, 2.2)
	-- Borde: piedras quemadas inclinadas hacia afuera y huesos cruzados.
	for k = 1, RIM_STONES do
		local a = k / RIM_STONES * math.pi * 2
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local at = nest + out * RIM + Vector3.new(0, 1.1, 0)
		local cframe = CFrame.lookAt(at, at + out) * CFrame.Angles(math.rad(-20), 0, 0)
		local size = Vector3.new(rng:NextNumber(3.8, 4.8), rng:NextNumber(2.2, 3), 2.4)
		P.part(
			parent,
			size,
			cframe,
			if k % 3 == 0 then P.OBSIDIAN2 else CHAR,
			{ material = Enum.Material.Slate }
		)
	end
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local mid = nest
			+ Vector3.new(math.cos(a), 0, math.sin(a)) * (RIM + 0.3)
			+ Vector3.new(0, 2.6, 0)
		local along = Vector3.new(-math.sin(a), rng:NextNumber(-0.2, 0.2), math.cos(a))
			* rng:NextNumber(2, 3.2)
		P.bar(parent, mid - along, mid + along, 0.55, 0.55, if k % 2 == 0 then BONE else CHAR)
	end
	for _, spec in EGGS do
		egg(parent, kept, nest, spec)
	end
	hatched(parent, nest + Vector3.new(0.6, 0, -5.4))
	for _ = 1, 6 do -- cáscaras sueltas
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(4, 12)
		local at = nest + Vector3.new(math.cos(a) * r, 0.75, math.sin(a) * r)
		local cframe = CFrame.new(at)
			* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.3), 0.3)
		P.part(parent, Vector3.new(1.6, 0.25, 1.2), cframe, SHELL[rng:NextInteger(1, 3)], {
			material = Enum.Material.SmoothPlastic,
		})
	end
	-- Brasas que suben del nido.
	local air =
		P.holder(kept, CFrame.new(nest + Vector3.new(0, 1.5, 0)), Vector3.new(RIM * 2, 1, RIM * 2))
	local sparks = P.emitter(
		air,
		Assets.Particles.Brasa,
		ColorSequence.new(P.MAGMA_HOT, P.EMBER),
		NumberSequence.new(0.5, 0),
		4
	)
	sparks.Shape = Enum.ParticleEmitterShape.Box
	sparks.Lifetime = NumberRange.new(2, 3.5)
	sparks.Speed = NumberRange.new(2, 5)
	sparks.Acceleration = Vector3.new(0, 2, 0)
	sparks.LightEmission = 1
end

return table.freeze(LairNest)
