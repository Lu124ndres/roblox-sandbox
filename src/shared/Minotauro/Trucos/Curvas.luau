--!strict
--[[
	Minotauro/Trucos/Curvas

	Curvas de 0 a 1 para armar los trucos (todas reciben y devuelven números):
		span(u, a, b)        avance de u entre a y b, recortado a 0..1
		smooth(t)            entra y sale lento
		easeIn(t)            arranca lento y termina de golpe (el cuadro del impacto)
		overshoot(t)         se pasa un poco y vuelve (llegada con rebote)
		bell(t)              sube y baja (medio seno)
		hold(u, a, b, c, d)  sube en [a, b], se queda y baja en [c, d]
		arc(t)               parábola de un salto: 0 al salir, 1 arriba, 0 al caer
		decay(u, a, rate)    golpe en a que se apaga (1 en a, tiende a 0)
]]

local Curvas = {}

function Curvas.span(u: number, a: number, b: number): number
	return math.clamp((u - a) / (b - a), 0, 1)
end

function Curvas.smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Curvas.easeIn(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * t
end

local BACK = 1.70158

function Curvas.overshoot(t: number): number
	t = math.clamp(t, 0, 1) - 1
	return 1 + (BACK + 1) * t * t * t + BACK * t * t
end

function Curvas.bell(t: number): number
	return math.sin(math.pi * math.clamp(t, 0, 1))
end

function Curvas.hold(u: number, a: number, b: number, c: number, d: number): number
	return Curvas.smooth(Curvas.span(u, a, b)) * (1 - Curvas.smooth(Curvas.span(u, c, d)))
end

function Curvas.arc(t: number): number
	t = math.clamp(t, 0, 1)
	return 4 * t * (1 - t)
end

function Curvas.decay(u: number, a: number, rate: number): number
	return if u < a then 0 else math.exp(-(u - a) * rate)
end

return table.freeze(Curvas)
