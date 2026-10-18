--!strict
--[[
	Zorro/Colas/Onda

	La onda propia de cada cola, sin estado: sale de la hora del servidor y de
	Azar, así todos los clientes ven lo mismo. Es la suma de tres senos de
	frecuencias sin proporción entre sí (1, φ y 1 + √2) más un ruido suave: nunca
	se repite igual ni dos colas van en espejo. Viaja de la raíz a la punta: el
	tramo j la ve (j - 1) · delta rad más tarde (a la frecuencia base de su cola).
	Las frecuencias son fijas por etapa (no dependen del estado): si cambiaran, un
	seno de la hora del servidor (~1.7e9 s) saltaría de fase. Lo que cambia con el
	estado es la amplitud.
		fan(c, t, j, ritmo, fine)   onda de abrir y cerrar (unos -1..1)
		fold(...)                   la de plegar (otras fases, más lenta)
		wag(c, t, j, ritmo, gusto)  meneo de contento: se acelera si le gusta más
		shake(c, t, j, ritmo)       la sacudida: onda rápida de la raíz a la punta
		pulse(tau)                  latigazo (tau: s desde que empezó): carga y golpe
	fine = false (lejos de la cámara): sin el ruido (es lo más caro y casi no se ve).
]]

local Azar = require(script.Parent.Parent.Parent.Minotauro.Azar)
local Medidas = require(script.Parent.Medidas)

local TAU = math.pi * 2
local BASE_HZ = 0.3 -- frecuencia base de la onda (por el ritmo de la etapa y de la cola)
local RATIOS = { 1, 1.6180339887, 2.4142135624 }
local WEIGHTS = { 0.62, 0.28, 0.14 }
local NOISE_HZ = 0.35
local NOISE = 0.25
local WAG_SLOW, WAG_FAST = 1.3, 2.6 -- Hz del meneo: contento y encantado
local WAG_DELAY = 0.06 -- s por tramo
local SHAKE_HZ, SHAKE_DELAY = 4.2, 0.05

local Onda = {}

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

-- Ruido suave (-1..1): valores de Azar unidos con una curva.
local function noise(seed: number, x: number): number
	local k = math.floor(x)
	local a, b = Azar.unit(seed, k), Azar.unit(seed, k + 1)
	return (a + (b - a) * smooth(x - k)) * 2 - 1
end

local function phase(c: Medidas.Cola, k: number): number
	return c.phases[k]
end

-- La onda de la cola c en el tramo j, con fases desde `first` (0 abrir, 3 plegar).
local function sum(
	c: Medidas.Cola,
	t: number,
	j: number,
	ritmo: number,
	fine: boolean,
	first: number,
	slow: number
): number
	local hz = BASE_HZ * ritmo * c.rate * slow
	local at = t - (j - 1) * c.delta / (TAU * hz)
	local total = 0
	for k = 1, 3 do
		total += WEIGHTS[k] * math.sin(TAU * hz * RATIOS[k] * at + phase(c, first + k))
	end
	if not fine then
		return total
	end
	return total + NOISE * noise(c.seed + first, at * NOISE_HZ * ritmo)
end

function Onda.fan(c: Medidas.Cola, t: number, j: number, ritmo: number, fine: boolean): number
	return sum(c, t, j, ritmo, fine, 0, 1)
end

function Onda.fold(c: Medidas.Cola, t: number, j: number, ritmo: number, fine: boolean): number
	return sum(c, t, j, ritmo, fine, 3, 0.83)
end

function Onda.wag(c: Medidas.Cola, t: number, j: number, ritmo: number, gusto: number): number
	local at = t - (j - 1) * WAG_DELAY
	local p = phase(c, 7)
	local slow = math.sin(TAU * WAG_SLOW * ritmo * at + p)
	local fast = math.sin(TAU * WAG_FAST * ritmo * at + p)
	local g = math.clamp(gusto, 0, 1)
	return slow * (1 - g) + fast * g
end

function Onda.shake(c: Medidas.Cola, t: number, j: number, ritmo: number): number
	local at = t - (j - 1) * SHAKE_DELAY
	return math.sin(TAU * SHAKE_HZ * math.sqrt(ritmo) * at + phase(c, 8))
end

-- Latigazo: se carga hacia adelante (-) y golpea hacia atrás (+); 0 fuera de [0, 0.75] s.
function Onda.pulse(tau: number): number
	if tau < 0 or tau > 0.75 then
		return 0
	end
	local load = math.sin(math.pi * math.clamp(tau / 0.18, 0, 1))
	local hit = math.sin(math.pi * math.clamp((tau - 0.18) / 0.3, 0, 1))
	local settle = math.sin(math.pi * math.clamp((tau - 0.48) / 0.27, 0, 1))
	return -0.35 * load + hit - 0.25 * settle
end

return table.freeze(Onda)
