--!strict
--[[
	OrcaMotion/Tricks/Respirar

	El gesto de soplar, como el de una ballena: un poco antes de soplar el
	cuerpo sube y la cabeza asoma (el espiráculo sale del agua), suelta el
	chorro (`blow`) y vuelve a bajar despacio. Lo usan los trucos (al volver de
	un salto o de una zambullida, al descansar flotando, al asomarse) y lo
	puede usar el nado normal con cada respiración:
		local amount, blowing = Respirar.at(segundosDesdeElSoplo, talla.pace)
		depth += Respirar.LIFT * amount; head += Respirar.HEAD * amount
	El tiempo va en segundos desde el soplo (negativo = antes).
]]

local Tricks = require(script.Parent)

local smooth, span = Tricks.smooth, Tricks.span

local RISE = 1.1 -- segundos antes del soplo en que empieza a subir
local BLOW = 0.7 -- segundos que dura el chorro
local SETTLE = 1.4 -- segundos en que vuelve a bajar después

local Respirar = {}

Respirar.LIFT = 0.05 -- cuánto sube el centro al soplar (altos)
Respirar.HEAD = 0.07 -- cuánto levanta la cabeza (rad)
Respirar.PITCH = 0.04 -- y la nariz (rad)

-- Cuánto está subida (0..1) y si está soplando, `t` segundos después del soplo.
-- pace: ritmo de la etapa (las grandes tardan más en subir y en bajar).
function Respirar.at(t: number, pace: number): (number, boolean)
	local rise, blow, settle = RISE * pace, BLOW * pace, SETTLE * pace
	local amount = smooth(span(t, -rise, 0)) * (1 - smooth(span(t, blow, blow + settle)))
	return amount, t >= 0 and t < blow
end

-- Segundos de subir antes del soplo, y del gesto entero (subir, soplar y bajar).
function Respirar.lead(pace: number): number
	return RISE * pace
end
function Respirar.length(pace: number): number
	return (RISE + BLOW + SETTLE) * pace
end

-- La pose de soplar sumada a una base (depth y pitch dados).
function Respirar.add(pose: Tricks.Pose, t: number, pace: number, size: number?): Tricks.Pose
	local amount, blowing = Respirar.at(t, pace)
	local k = size or 1
	pose.depth = (pose.depth or 0) + Respirar.LIFT * amount * k
	pose.pitch = (pose.pitch or 0) + Respirar.PITCH * amount
	pose.head = (pose.head or 0) + Respirar.HEAD * amount
	if blowing then
		pose.blow = true
	end
	return pose
end

return table.freeze(Respirar)
