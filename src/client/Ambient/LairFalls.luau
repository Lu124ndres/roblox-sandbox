--!strict
--[[
	LairFalls

	Cascadas y ríos de lava de la guarida volcánica. Cada una nace de una
	grieta encendida en el acantilado (bajo el paseo del borde, nadie la
	pisa), cae pegada a la pared hasta la repisa, forma un charco, corre por
	la repisa de ceniza serpenteando y se derrama por el borde del pozo a la
	laguna de lava. El cuerpo es de neón (brilla aunque no haya partículas);
	encima, un Beam con la textura del humo teñida de fuego que avanza y hace
	que se vea correr. Al pie, salpicaduras de fuego, humo y una luz.
	Ángulos elegidos para no cruzar las rocas (Dragon/Guarida) ni los props
	del hábitat (Config.Habitats).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local LairParts = require(script.Parent.LairParts)

local P = LairParts
local LAVA = Guarida.lava
local ANGLES = { 15, 105, 215, 295 } -- grados
local GAP = 1.8 -- studs que la cascada se separa de la pared (el terreno es de vóxeles)
local FLOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, P.MAGMA_HOT),
	ColorSequenceKeypoint.new(0.5, P.MAGMA),
	ColorSequenceKeypoint.new(1, P.MAGMA_HOT),
})
-- Recorrido: radio y cuánto se aparta hacia el costado (serpentea). Del acantilado a la lava.
local FALL = { 201, 197, 193.5, 190.6 }
local RIVER = { { 187, 0 }, { 176, 3.5 }, { 163, -3 }, { 151, 1 } }
local DROP = { 151, 146, 140, 131 }

local LairFalls = {}

local rng = Random.new(5)

-- Beam que corre de a hacia b, con la textura avanzando (A0 → A1).
local function stream(holder: BasePart, a: Vector3, b: Vector3, width: number)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = holder, holder -- primero el padre: WorldPosition es relativa a él
	a0.WorldPosition, a1.WorldPosition = a, b
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Texture = Assets.Particles.Mist
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 7
	beam.TextureSpeed = rng:NextNumber(0.8, 1.2)
	beam.Color = FLOW
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Transparency = NumberSequence.new(0.15)
	beam.Width0, beam.Width1 = width, width
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Parent = holder
end

-- Un tramo de lava (neón) de a a b, con su Beam encima.
local function segment(
	parent: Instance,
	holder: BasePart,
	a: Vector3,
	b: Vector3,
	width: number,
	lift: number
)
	local along = (b - a).Unit * 0.6 -- un poco más largo: sin huecos en los codos
	P.bar(parent, a - along, b + along, width, 1.2, P.MAGMA, { material = Enum.Material.Neon })
	local up = Vector3.new(0, lift, 0)
	stream(holder, a + up, b + up, width * 0.8)
end

-- Salpicadura continua al pie (fuego y humo) con su luz.
local function splash(parent: Instance, at: Vector3, size: number)
	local holder = P.holder(parent, CFrame.new(at), Vector3.new(size, 1, size))
	local fire = P.emitter(
		holder,
		Assets.Particles.Spark,
		ColorSequence.new(P.MAGMA_HOT, P.EMBER),
		NumberSequence.new(0.6, 0),
		12
	)
	fire.Shape = Enum.ParticleEmitterShape.Box
	fire.Lifetime = NumberRange.new(0.6, 1.2)
	fire.Speed = NumberRange.new(8, 16)
	fire.SpreadAngle = Vector2.new(35, 35)
	fire.Acceleration = Vector3.new(0, -30, 0)
	fire.LightEmission = 1
	local smoke = P.emitter(
		holder,
		Assets.Particles.Mist,
		ColorSequence.new(P.SMOKE),
		NumberSequence.new(4, 14),
		2
	)
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Speed = NumberRange.new(4, 8)
	smoke.Transparency = NumberSequence.new(0.5, 1)
	P.light(holder, P.MAGMA, 2, 26)
end

local function fall(parent: Instance, degrees: number)
	local angle = math.rad(degrees)
	local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local side = Vector3.new(-out.Z, 0, out.X)
	local holder = P.holder(parent, CFrame.new(P.at(angle, 170, 0)))
	holder.Name = `Cascada{degrees}`
	-- Grieta en el acantilado: de donde sale.
	local source = P.at(angle, FALL[1] - GAP, P.ground(FALL[1]) + 1)
	local crack = CFrame.lookAt(source, source - out)
	P.part(
		parent,
		Vector3.new(9, 5, 2),
		crack * CFrame.new(0, 0, 1.2),
		P.EMBER,
		{ material = Enum.Material.Neon }
	)
	P.part(parent, Vector3.new(13, 8, 2.5), crack * CFrame.new(0, 0.5, 2), P.OBSIDIAN, {
		material = Enum.Material.CrackedLava,
	})
	-- La caída, pegada a la pared.
	local last = source
	for k = 2, #FALL do
		local nextPoint = P.at(angle, FALL[k] - GAP, P.ground(FALL[k]) + 0.4)
		segment(parent, holder, last, nextPoint, 6 + k * 0.5, 0.2)
		last = nextPoint
	end
	-- Charco al pie y el río por la repisa.
	local pool = P.at(angle, RIVER[1][1], P.ground(RIVER[1][1]))
	segment(parent, holder, last, pool + Vector3.new(0, 0.25, 0), 7.5, 0.2)
	P.column(
		parent,
		pool - Vector3.new(0, 0.6, 0),
		1,
		6,
		P.MAGMA,
		{ material = Enum.Material.Neon }
	)
	splash(parent, pool + Vector3.new(0, 1, 0), 8)
	last = pool + Vector3.new(0, 0.25, 0)
	for k = 2, #RIVER do
		local radius, swing = RIVER[k][1], RIVER[k][2]
		local nextPoint = P.at(angle, radius, P.ground(radius) + 0.25) + side * swing
		segment(parent, holder, last, nextPoint, 6.5, 0.7)
		last = nextPoint
	end
	-- Se derrama por el borde del pozo hasta la laguna.
	for k = 2, #DROP do
		local radius = DROP[k]
		local y = if k == #DROP then LAVA else P.ground(radius) + 1.2
		local nextPoint = P.at(angle, radius, y) + side * RIVER[#RIVER][2]
		segment(parent, holder, last, nextPoint, 6, 0.5)
		last = nextPoint
	end
	splash(parent, last + Vector3.new(0, 0.5, 0), 6)
end

function LairFalls.build(parent: Instance)
	for _, degrees in ANGLES do
		fall(parent, degrees)
	end
end

return table.freeze(LairFalls)
