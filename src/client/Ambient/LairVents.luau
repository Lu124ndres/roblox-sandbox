--!strict
--[[
	LairVents

	Las bocas de los géiseres de la guarida volcánica (las hace reventar
	LairGeysers): en la repisa, un montículo de obsidiana; en la laguna, un
	anillo de costra flotando en la lava. Cada una tiene su brillo de neón,
	su luz (apagada hasta que revienta) y sus emisores: el burbujeo del aviso
	(continuo, apagado) y las ráfagas del estallido (fuego, brasas y humo).
	Lugares elegidos lejos de las rocas (Dragon/Guarida), las cascadas
	(LairFalls), los cristales y los props del hábitat.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local LairParts = require(script.Parent.LairParts)

type Spot = { angle: number, radius: number, height: number, lake: boolean }

local P = LairParts
local LAVA = Guarida.lava
-- Ángulo (grados), radio y alto de la columna. Repisa (lake = false) o laguna.
local SPOTS: { Spot } = {
	{ angle = 52, radius = 168, height = 44, lake = false },
	{ angle = 197, radius = 165, height = 44, lake = false },
	{ angle = 95, radius = 78, height = 58, lake = true },
	{ angle = 215, radius = 84, height = 58, lake = true },
	{ angle = 330, radius = 88, height = 58, lake = true },
}

export type Vent = {
	mouth: Vector3,
	height: number,
	glow: Part,
	glowSize: Vector3,
	light: PointLight,
	warn: ParticleEmitter,
	fire: ParticleEmitter,
	embers: ParticleEmitter,
	smoke: ParticleEmitter,
}

local LairVents = {}

local function emitters(
	holder: BasePart
): (ParticleEmitter, ParticleEmitter, ParticleEmitter, ParticleEmitter)
	local warn = P.emitter(
		holder,
		Assets.Particles.Spark,
		ColorSequence.new(P.MAGMA_HOT),
		NumberSequence.new(0.8, 0),
		30
	)
	warn.Lifetime = NumberRange.new(0.4, 0.8)
	warn.Speed = NumberRange.new(6, 12)
	warn.SpreadAngle = Vector2.new(30, 30)
	warn.LightEmission = 1
	warn.Enabled = false
	local fire = P.emitter(
		holder,
		Assets.Particles.FuegoFlip,
		ColorSequence.new(P.MAGMA_HOT, P.EMBER),
		NumberSequence.new(6, 12),
		0
	)
	fire.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	fire.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	fire.Lifetime = NumberRange.new(0.7, 1.1)
	fire.Speed = NumberRange.new(45, 65)
	fire.SpreadAngle = Vector2.new(7, 7)
	fire.LightEmission = 1
	local embers = P.emitter(
		holder,
		Assets.Particles.Brasa,
		ColorSequence.new(P.MAGMA_HOT, P.EMBER),
		NumberSequence.new(0.9, 0.2),
		0
	)
	embers.Lifetime = NumberRange.new(2, 3)
	embers.Speed = NumberRange.new(35, 60)
	embers.SpreadAngle = Vector2.new(22, 22)
	embers.Acceleration = Vector3.new(0, -45, 0)
	embers.LightEmission = 1
	local smoke = P.emitter(
		holder,
		Assets.Particles.Mist,
		ColorSequence.new(P.SMOKE),
		NumberSequence.new(10, 30),
		0
	)
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Speed = NumberRange.new(15, 25)
	smoke.Transparency = NumberSequence.new(0.35, 1)
	return warn, fire, embers, smoke
end

local function vent(parent: Instance, spot: Spot): Vent
	local angle = math.rad(spot.angle)
	local floor = if spot.lake then LAVA else P.ground(spot.radius)
	local base = P.at(angle, spot.radius, floor)
	local mouthY: number
	if spot.lake then -- anillo de costra flotando en la lava
		P.column(
			parent,
			base - Vector3.new(0, 0.2, 0),
			0.8,
			7,
			P.OBSIDIAN2,
			{ material = Enum.Material.CrackedLava }
		)
		mouthY = floor + 0.6
	else -- montículo de obsidiana
		P.column(parent, base - Vector3.new(0, 1, 0), 2.6, 6.5, P.OBSIDIAN, {})
		P.column(parent, base + Vector3.new(0, 1.4, 0), 1.4, 4, P.OBSIDIAN2, {})
		mouthY = floor + 2.8
	end
	local mouth = Vector3.new(base.X, mouthY, base.Z)
	local glowSize = Vector3.new(0.3, 4.4, 4.4)
	local glow = P.part(parent, glowSize, CFrame.new(mouth) * P.UPRIGHT, P.MAGMA, {
		shape = Enum.PartType.Cylinder,
		material = Enum.Material.Neon,
		transparency = 0.45,
	})
	local holder = P.holder(parent, CFrame.new(mouth)) -- los emisores salen hacia arriba (Top)
	local warn, fire, embers, smoke = emitters(holder)
	local light = P.light(holder, P.MAGMA, 0, 45)
	return {
		mouth = mouth + Vector3.new(0, 0.5, 0),
		height = spot.height,
		glow = glow,
		glowSize = glowSize,
		light = light,
		warn = warn,
		fire = fire,
		embers = embers,
		smoke = smoke,
	}
end

-- Arma todas las bocas en parent.
function LairVents.build(parent: Instance): { Vent }
	local vents = {}
	for _, spot in SPOTS do
		table.insert(vents, vent(parent, spot))
	end
	return vents
end

return table.freeze(LairVents)
