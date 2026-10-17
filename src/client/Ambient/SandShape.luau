--!strict
--[[
	SandShape

	La forma del desierto del cráter (el hábitat del Minotauro, GiantDef.sand):
	la altura de la arena en cada punto y qué asoma ahí.
		llano    en el centro, casi a waterLevel: ahí camina el minotauro (sus pies
		         van a waterLevel + lift), así que las ondas son bajas (±1 stud).
		ondas    crestas largas que deja el viento, todas en la misma dirección
		         (WIND), un poco curvas.
		dunas    lomas suaves que cambian alrededor del cráter.
		bancos   contra el acantilado la arena se amontona (hasta ~8 studs).
		rocas    mesetas de arenisca que asoman de los bancos, junto a la pared,
		         lejos de donde el minotauro se para a comer.
	Solo números y cuentas: SandTerrain la escribe en vóxeles; SandProps y
	SandDecor apoyan cosas encima.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local L = WorldLayout
local CENTER = WorldZones.craterCenter
local BASE = L.waterLevel
local BANK_START = 135 -- desde este radio la arena empieza a subir hacia la pared
local BANK_WIDTH = 55
-- Rocas: ángulo (grados), radio, radio de la roca, alto sobre la arena del lugar.
-- En los huecos que dejan los props del hábitat (Config.Habitats.byGiant.Minotauro).
local ROCKS = {
	{ 55, 182, 13, 9 },
	{ 128, 184, 16, 12 },
	{ 166, 180, 11, 7 },
	{ 212, 183, 14, 10 },
	{ 330, 184, 12, 8 },
	{ 20, 184, 10, 6 },
	{ 284, 186, 9, 6 },
}

local SandShape = {}

SandShape.WIND = Vector3.new(0.8, 0, 0.6).Unit -- de dónde a dónde sopla (en el plano)
SandShape.REACH = L.craterLakeRadius + 10 -- más afuera es acantilado: no hay arena
SandShape.MAX_TOP = BASE + 26 -- lo más alto que llega (la cima de la roca más alta)
SandShape.SHELL = 10 -- studs de arena bajo waterLevel (debajo queda hueco: nadie lo ve)

-- Las rocas en el mundo: { centro (x, z), radio, alto }.
type Rock = { at: Vector3, radius: number, height: number }
local rocks: { Rock } = {}
for _, rock in ROCKS do
	local angle = math.rad(rock[1])
	table.insert(rocks, {
		at = CENTER + Vector3.new(math.cos(angle), 0, math.sin(angle)) * rock[2],
		radius = rock[3],
		height = rock[4],
	})
end

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Altura de la arena sola (sin rocas) en (x, z).
local function sandAt(x: number, z: number): number
	local dx, dz = x - CENTER.X, z - CENTER.Z
	local r = math.sqrt(dx * dx + dz * dz)
	local angle = math.atan2(dz, dx)
	local bank = smooth((r - BANK_START) / BANK_WIDTH)
	-- Ondas de ~28 studs (los vóxeles miden 4: más finas no se verían).
	local along = x * SandShape.WIND.X + z * SandShape.WIND.Z
	local across = x * SandShape.WIND.Z - z * SandShape.WIND.X
	local ripple = 0.7 * math.sin(along * 0.22 + 1.6 * math.sin(across * 0.018))
	local dune = 1.3
		* (0.5 + 0.5 * math.sin(angle * 4 + r * 0.045 + 0.7))
		* (0.5 + 0.5 * math.sin(angle * 9 - r * 0.02))
	local drift = bank * (4.5 + 2.5 * math.sin(angle * 6 + 0.4) + 1.2 * math.sin(angle * 13))
	return BASE + ripple * (1 - 0.6 * bank) + dune + drift
end

-- Altura de la superficie en (x, z) y su material: arena o, donde asoma, arenisca.
function SandShape.sample(x: number, z: number): (number, Enum.Material)
	local top = sandAt(x, z)
	local rockTop = -math.huge
	for _, rock in rocks do
		local d = Vector3.new(x - rock.at.X, 0, z - rock.at.Z).Magnitude / rock.radius
		if d < 1 then
			-- Meseta: lados empinados y la cima casi plana, con un borde irregular.
			local wobble = 0.8 * math.sin(x * 0.4) * math.cos(z * 0.35)
			rockTop = math.max(rockTop, top + rock.height * math.sqrt(1 - d ^ 4) + wobble)
		end
	end
	if rockTop > top + 0.5 then
		return rockTop, Enum.Material.Sandstone
	end
	return top, Enum.Material.Sand
end

-- Solo la altura (para apoyar cosas encima).
function SandShape.top(x: number, z: number): number
	return (SandShape.sample(x, z))
end

-- La más baja entre el centro y cuatro puntos alrededor (para que nada flote en una loma).
function SandShape.lowest(cframe: CFrame, halfX: number, halfZ: number): number
	local lowest = math.huge
	for _, offset in
		{
			Vector3.zero,
			Vector3.new(halfX, 0, 0),
			Vector3.new(-halfX, 0, 0),
			Vector3.new(0, 0, halfZ),
			Vector3.new(0, 0, -halfZ),
		}
	do
		local point = cframe * offset
		lowest = math.min(lowest, SandShape.top(point.X, point.Z))
	end
	return lowest
end

return table.freeze(SandShape)
