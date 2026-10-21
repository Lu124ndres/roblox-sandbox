--!strict
--[[
	OrcaMotion/Rig/Ritmo

	El ritmo del nado de la orca v2 (lo usa Body cada cuadro):
		- Como un cetáceo de verdad, a más velocidad aletea más seguido
		  (frecuencia casi proporcional a la velocidad) y la onda crece poco.
		- Series de aletazos y planeo: el tiempo se corta en tramos de largo
		  variable y un hash del tramo decide si planea (Swim.glide es la
		  probabilidad). Es el mismo en todos los clientes. Al planear la cola
		  casi se queda quieta y el último aletazo termina lento; al volver da un
		  aletazo de fuerza. No planea en curvas cerradas, rápida, en un truco ni
		  al comer.
		- Ningún aletazo es igual al anterior: la fuerza varía apenas.
		- Al sostenerse casi vertical (comer, asomarse) da aletazos cortos y
		  rápidos.
		- Respirar: al llegar arriba sopla (el cuerpo sube un poco) y después
		  rueda hacia abajo arqueando el lomo, como una orca al sumergirse.
	`viejo` es la cuenta de antes, para la Orca fantasma.
]]

local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)

local GLIDE_SLOT = 2.4 -- s: largo medio de un tramo de aletazos o de planeo
local GLIDE_WARP = 1.0 -- s: deforma el tiempo para que los tramos no midan lo mismo (< 1/0.21)
local GLIDE_BLEND = 0.3 -- fracción final del tramo en que pasa al siguiente
local GLIDE_AMP = 0.15 -- lo que queda de la onda al planear
local GLIDE_HZ = 0.35 -- y de su frecuencia (el aletazo termina lento)
local KICK = 0.3 -- el aletazo de fuerza al dejar de planear
local TREAD_HZ = 0.7 -- vertical: aletazos más seguidos
local TREAD_AMP = 0.4 -- y más cortos
local BLOW_SECONDS = 1.1 -- lo que dura el soplido alrededor del momento de respirar
local ROLL_START, ROLL_SECONDS = 0.6, 2.6 -- después de soplar rueda hacia abajo
local ROLL_ARCH = 0.18 -- rad de lomo arqueado al rodar

export type Beat = { hz: number, effort: number, glide: number, kick: number }

local Ritmo = {}

local function hash(n: number): number
	local x = math.sin(n * 91.3458 + 47.853) * 43758.5453
	return x - math.floor(x)
end

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- El tramo n: 1 = aletea, 0 = planea. Nunca más de dos tramos de planeo seguidos
-- (si los dos anteriores salieron de planeo, este aletea).
local function on(n: number, chance: number): number
	local glides = hash(n) < chance and not (hash(n - 1) < chance and hash(n - 2) < chance)
	return if glides then 0 else 1
end

-- 1 = aletea, 0 = planea, en el instante `now` (hora del servidor).
local function stroking(now: number, chance: number): (number, number)
	local tau = (now + GLIDE_WARP * math.sin(now * 0.21)) / GLIDE_SLOT
	local slot = math.floor(tau)
	local f = tau - slot
	local here, nextOne = on(slot, chance), on(slot + 1, chance)
	local s = here + (nextOne - here) * smooth((f - (1 - GLIDE_BLEND)) / GLIDE_BLEND)
	local kick = 0
	if here == 1 and on(slot - 1, chance) == 0 then
		kick = 1 - smooth(f / 0.35) -- primer aletazo después de planear
	end
	return s, kick
end

-- busy 0..1: curva, truco o comida (no planea). tread 0..1: vertical.
function Ritmo.step(
	out: Beat,
	swim: Perfil.Swim,
	now: number,
	pace: number,
	anger: number,
	busy: number,
	tread: number,
	phase: number
)
	local stroke, kick = stroking(now, swim.glide)
	local free = math.clamp(1 - busy - math.max(pace - 1.25, 0) * 2, 0, 1)
	stroke = 1 - (1 - stroke) * free
	kick *= free
	local vary = 1 + 0.06 * math.sin(phase * 0.31) + 0.04 * math.sin(phase * 0.137 + 2)
	out.hz = swim.beat
		* (0.4 + 0.6 * pace)
		* (1 + 0.5 * anger)
		* (GLIDE_HZ + (1 - GLIDE_HZ) * stroke)
		* (1 + TREAD_HZ * tread)
		* (1 + 0.15 * kick)
	out.effort = (0.55 + 0.45 * math.min(pace, 1.6))
		* (1 + 0.3 * anger)
		* swim.amplitude
		* (GLIDE_AMP + (1 - GLIDE_AMP) * stroke)
		* (1 - TREAD_AMP * tread)
		* (1 + KICK * kick)
		* vary
	out.glide, out.kick = 1 - stroke, kick
end

-- La cuenta de antes (Orca fantasma): planea con una onda de 7 s.
function Ritmo.viejo(out: Beat, swim: Perfil.Swim, now: number, pace: number, anger: number)
	local glide = 1 - swim.glide * (0.5 + 0.5 * math.sin(now * math.pi * 2 / 7))
	out.effort = (0.45 + pace * 0.75 + anger * 0.4) * glide * swim.amplitude
	out.hz = swim.beat * (0.45 + pace * 0.55 + anger * 0.5)
	out.glide, out.kick = 0, 0
end

-- Respirar (crucero): cuánto sopla (0..1) y cuánto arquea el lomo al rodar,
-- por `calm` (0 en un truco o al comer: no lo hace).
function Ritmo.breath(cycle: number?, seconds: number, calm: number): (number, number)
	if not cycle then
		return 0, 0
	end
	local since = cycle * seconds -- segundos desde que llegó arriba
	local away = math.min(since, seconds - since)
	local blow = 1 - smooth(away / BLOW_SECONDS)
	local t = (since - ROLL_START) / ROLL_SECONDS
	local roll = if t > 0 and t < 1 then 0.5 - 0.5 * math.cos(2 * math.pi * t) else 0
	return blow * calm, ROLL_ARCH * roll * calm
end

return table.freeze(Ritmo)
