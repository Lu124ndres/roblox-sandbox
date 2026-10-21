--!strict
--[[
	OrcaMotion/Path/Aliento

	Cómo respira la orca, como las de verdad: una serie de 3 a 5 respiraciones cortas
	(asoma el lomo y el espiráculo, sopla y se hunde poco) y después una inmersión más
	larga y más honda; como sigue nadando, vuelve a salir más lejos. Cuántas, cada
	cuánto y cuánto dura la inmersión cambian en cada serie (hash sin estado, igual en
	todos los clientes). Todo sale del perfil `Breath` de la etapa:
		seconds  la serie entera dura ~seconds × CYCLE (las cortas, ~seconds × GAP cada una)
		shallow  altura del centro al soplar (altos del modelo; negativa = bajo el agua)
		deep     hasta dónde se hunde entre soplidos (SINK del camino) y, por DIVE_DEPTH,
		         lo hondo de la inmersión larga.
	`phase` va de 0 a 1 entre un soplido y el siguiente: vuelve a 0 justo al soplar
	(OrcaFx echa el chorro ahí).
]]

local Azar = require(script.Parent.Parent.Parent.Parent.Minotauro.Azar)

local GAP = 0.32 -- una respiración corta dura seconds × GAP
local DIVE = 1.5 -- la inmersión larga dura seconds × DIVE
local SHORTS = 4 -- respiraciones cortas de una serie media (para el largo de la serie)
local JITTER = 0.25 -- cuánto se corre el comienzo de cada serie (fracción de la serie)
local MIN_DIVE = 0.6 -- la inmersión nunca dura menos que esto de la normal
local SINK = 0.6 -- entre soplidos baja esta parte del camino de shallow a deep
local DIVE_DEPTH = 2.2 -- la inmersión larga baja deep × esto
local DIVE_EDGE = 0.25 -- parte de la inmersión que tarda en bajar (y en subir)
local DOMAIN = 7777 -- separa este azar del de otros sistemas

export type Breath = { seconds: number, shallow: number, deep: number }

local Aliento = {}

-- Fase (0..1) entre soplidos, si está en la inmersión larga y segundos desde el último soplido.
function Aliento.phase(t: number, seconds: number): (number, boolean, number)
	local gap, dive = seconds * GAP, seconds * DIVE
	local period = SHORTS * gap + dive
	local c = math.floor(t / period)
	local function start(k: number): number
		return k * period + JITTER * period * Azar.unit(k * 8 + 1, DOMAIN)
	end
	if t < start(c) then
		c -= 1
	end
	local s0, s1 = start(c), start(c + 1)
	local n = 2 + math.min(2, math.floor(3 * Azar.unit(c * 8 + 2, DOMAIN)))
	local g = gap * (0.85 + 0.3 * Azar.unit(c * 8 + 3, DOMAIN))
	while n > 1 and (s1 - s0) - n * g < MIN_DIVE * dive do
		n -= 1
	end
	local u = t - s0
	if u < n * g then
		local k = math.floor(u / g)
		return (u - k * g) / g, false, u - k * g
	end
	return (u - n * g) / ((s1 - s0) - n * g), true, u - n * g
end

-- Altura del centro (altos del modelo) a la hora `t`.
function Aliento.depth(t: number, breath: Breath): number
	local phase, diving = Aliento.phase(t, breath.seconds)
	local shallow = breath.shallow
	if diving then
		local plateau = math.clamp(phase / DIVE_EDGE, 0, 1)
		local leave = math.clamp((1 - phase) / DIVE_EDGE, 0, 1)
		plateau = plateau * plateau * (3 - 2 * plateau) * (leave * leave * (3 - 2 * leave))
		return shallow + (breath.deep * DIVE_DEPTH - shallow) * plateau
	end
	local sink = shallow + (breath.deep - shallow) * SINK
	local bob = math.sin(math.pi * phase)
	return shallow + (sink - shallow) * (bob * bob)
end

return table.freeze(Aliento)
