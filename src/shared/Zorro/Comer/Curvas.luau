--!strict
--[[
	Zorro/Comer/Curvas

	Curvas de 0 a 1 para armar las reacciones al comer (todas reciben y devuelven
	números):
		span(u, a, b)        avance de u entre a y b, recortado a 0..1
		smooth(t)            entra y sale lento
		easeOut(t)           arranca de golpe y frena (el mordisco: el cuadro del
		                     impacto va sin suavizar)
		overshoot(t)         se pasa un poco y vuelve (llegada con rebote)
		bell(t)              sube y baja (medio seno)
		hold(u, a, b, c, d)  sube en [a, b], se queda y baja en [c, d]
		arc(t)               parábola de un salto: 0 al salir, 1 arriba, 0 al caer
		decay(u, a, rate)    golpe en a que se apaga (1 en a, tiende a 0)
		wave(u, n)           n vaivenes completos entre 0 y 1 (seno)
]]

local Curvas = {}

function Curvas.span(u: number, a: number, b: number): number
	return math.clamp((u - a) / (b - a), 0, 1)
end

function Curvas.smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Curvas.easeOut(t: number): number
	t = 1 - math.clamp(t, 0, 1)
	return 1 - t * t * t
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

function Curvas.wave(u: number, n: number): number
	return math.sin(2 * math.pi * n * u)
end

return table.freeze(Curvas)
