--!strict
--[[
	OrcaMotion/Tricks/Salto/Fisica

	Los números del salto completo: con qué velocidad sale del agua para llegar
	a su altura con la gravedad de su tamaño, cuánto vuela, con qué velocidad
	cae y cuánto tarda el agua en frenarla. Del tiempo que sobra salen la toma
	de impulso, el planeo abajo, la subida y el soplo.
]]

local Respirar = require(script.Parent.Parent.Respirar)
local Tricks = require(script.Parent.Parent)

export type Style = {
	talla: Tricks.Talla?, -- sin talla, la física se ajusta a `seconds` (los festejos al comer)
	sink: number?, -- cuánto se hunde el centro después de caer (altos)
	flop: boolean?, -- cae de panza
	times: number?, -- saltos seguidos
	size: number?, -- salpicadura de la caída (1 normal, 2.5 la ola de la anciana)
	exit: number?, -- ángulo de salida (rad)
	low: number?, -- hondo desde donde toma impulso (altos; la anciana no cabe más abajo)
}
export type Plan = {
	g: number, -- gravedad (altos/s²)
	apex: number, -- altura del centro en el pico
	land: number, -- altura del centro cuando toca el agua al caer
	low: number, -- hondo desde donde toma impulso
	sink: number, -- hondo al que se hunde después
	vUp: number, -- velocidad al salir (altos/s)
	vDown: number, -- y al caer
	tL: number, -- segundos acelerando hasta el agua
	tAir: number, -- en el aire
	tau: number, -- constante de tiempo del frenado en el agua
	tSink: number, -- hundiéndose
	tRe: number, -- rebote entre saltos seguidos
	tApp: number, -- tomando impulso
	tHold: number, -- planeando abajo
	tRise: number, -- subiendo
	tBlow: number, -- soplando
	blowAt: number, -- momento del soplo dentro de tBlow
	exit: number, -- ángulo de salida
	landPitch: number, -- y de caída
	turn: number, -- giro sobre su eje en el aire (rad)
	upright: number, -- vuelta en que se endereza (rad)
	times: number,
	flop: boolean,
	size: number,
	pace: number,
}

local EXIT = 1.2 -- rad (~69°): sale casi vertical
local LAND_PITCH, FLOP_PITCH = 0.2, -0.05 -- cae casi horizontal; de panza, plana
local LAND, FLOP_LAND = 0.22, 0.28 -- altura del centro cuando el flanco (o la panza) toca el agua
local LOW = 0.85 -- hondo desde donde toma impulso (altos): el hocico todavía bajo el agua
local SINK = 1.4 -- hundimiento después de caer (altos)
local SINK_TAUS = 3 -- se hunde 3 constantes de tiempo (95 % del camino)
local REBOUND = 2.2 -- entre saltos seguidos el rebote dura esto por (hondo / velocidad)
local SPLIT = { approach = 0.4, hold = 0.25, rise = 0.35 } -- lo que sobra, sin el soplo
local BLOW_SHARE = 0.45 -- el soplo usa a lo sumo esta parte de lo que sobra
local COMPAT = { physics = 0.8, sink = 0.35, low = 0.5 } -- sin talla: la física ocupa el 80 %
local MIN_REST = 0.4 -- segundos mínimos para lo que no es física

local Fisica = {}

Fisica.SINK_TAUS = SINK_TAUS

type Motion = {
	vUp: number,
	vDown: number,
	tL: number,
	tAir: number,
	tau: number,
	tSink: number,
	tRe: number,
}

local function motion(apex: number, land: number, low: number, sink: number, g: number): Motion
	local vUp, vDown = math.sqrt(2 * g * apex), math.sqrt(2 * g * (apex - land))
	local tau = (land + sink) / vDown
	return {
		vUp = vUp,
		vDown = vDown,
		tL = 2 * low / vUp, -- aceleración constante desde el fondo hasta el agua
		tAir = vUp / g + vDown / g,
		tau = tau,
		tSink = SINK_TAUS * tau,
		tRe = REBOUND * (land + low) / vDown,
	}
end

local function physics(m: Motion, times: number): number
	return times * (m.tL + m.tAir) + (times - 1) * m.tRe + m.tSink
end

function Fisica.solve(apex: number, twist: number, seconds: number, style: Style?): Plan
	local s: Style = style or {}
	local flop, times = s.flop == true, math.max(1, s.times or 1)
	local land = if flop then FLOP_LAND else LAND
	local low, sink = s.low or LOW, s.sink or SINK
	local g = 1
	if s.talla then
		g = s.talla.gravity
	else -- la gravedad que hace entrar la física en el 80 % del truco
		low, sink = COMPAT.low, COMPAT.sink
		g = (physics(motion(apex, land, low, sink, 1), times) / (COMPAT.physics * seconds)) ^ 2
	end
	local m = motion(apex, land, low, sink, g)
	local pace = if s.talla then s.talla.pace else 1
	local rest = math.max(MIN_REST, seconds - physics(m, times))
	local tBlow = math.min(rest * BLOW_SHARE, Respirar.length(pace)) -- el gesto entero si cabe
	local other = rest - tBlow
	return {
		g = g,
		apex = apex,
		land = land,
		low = low,
		sink = sink,
		vUp = m.vUp,
		vDown = m.vDown,
		tL = m.tL,
		tAir = m.tAir,
		tau = m.tau,
		tSink = m.tSink,
		tRe = m.tRe,
		tApp = other * SPLIT.approach,
		tHold = other * SPLIT.hold,
		tRise = other * SPLIT.rise,
		tBlow = tBlow,
		blowAt = math.min(Respirar.lead(pace), tBlow * 0.35),
		exit = s.exit or EXIT,
		landPitch = if flop then FLOP_PITCH else LAND_PITCH,
		turn = 2 * math.pi * twist,
		upright = 2 * math.pi * math.floor(twist + 0.5),
		times = times,
		flop = flop,
		size = s.size or 1,
		pace = pace,
	}
end

return table.freeze(Fisica)
