--!strict
--[[
	Zorro/Conductas/Curvas

	Curvas de 0 a 1 para armar las conductas del zorro (todas reciben y devuelven
	números, sin estado). Las mismas ideas que Minotauro/Trucos/Curvas:
		span(u, a, b)        avance de u entre a y b, recortado a 0..1
		smooth(t)            entra y sale lento
		easeIn(t)            arranca lento y termina de golpe (el cuadro del impacto)
		overshoot(t)         se pasa un poco y vuelve (llegada con rebote)
		bell(t)              sube y baja (medio seno)
		hold(u, a, b, c, d)  sube en [a, b], se queda y baja en [c, d]
		arc(t)               parábola de un salto: 0 al salir, 1 arriba, 0 al caer
		pulse(u, a, w)       un golpe corto y suave centrado en a, de ancho w
		beat(u, a, b, n)     n vaivenes (-1..1) entre a y b que nacen y mueren suaves
	Y lo que sale del azar de la conducta (r: 0..1, Zorro/Azar, el mismo en todos
	los clientes) y de la etapa:
		azar(r, k)           otro número 0..1 sacado de r (k: cuál), para no usar el
		                     mismo r en dos decisiones
		entre(r, k, lo, hi)  un número entre lo y hi
		veces(r, k, lo, hi)  un entero entre lo y hi (repeticiones)
		lado(r, k)           1 (su izquierda) o -1 (su derecha)
		pace(etapa)          cuánto más lento lo hace la etapa (la cría rápida, la
		                     forma final lenta y con peso)
		peso(etapa, ...)     el valor de la etapa en una lista de cuatro
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

function Curvas.pulse(u: number, a: number, w: number): number
	local x = (u - a) / w
	if x <= -1 or x >= 1 then
		return 0
	end
	return 0.5 + 0.5 * math.cos(math.pi * x)
end

-- n vaivenes entre a y b: un seno que crece y se apaga con el borde de la ventana
-- (nunca arranca ni corta de golpe).
function Curvas.beat(u: number, a: number, b: number, n: number): number
	local t = Curvas.span(u, a, b)
	if t <= 0 or t >= 1 then
		return 0
	end
	local edge = math.min(1, t * n * 2, (1 - t) * n * 2)
	return math.sin(2 * math.pi * n * t) * Curvas.smooth(edge)
end

function Curvas.azar(r: number, k: number): number
	return (r * (7.13 * k + 3.7) + 0.6180339 * k) % 1
end

function Curvas.entre(r: number, k: number, lo: number, hi: number): number
	return lo + (hi - lo) * Curvas.azar(r, k)
end

function Curvas.veces(r: number, k: number, lo: number, hi: number): number
	return math.min(hi, lo + math.floor(Curvas.azar(r, k) * (hi - lo + 1)))
end

function Curvas.lado(r: number, k: number): number
	return if Curvas.azar(r, k) < 0.5 then 1 else -1
end

local PACE = { 0.85, 1, 1.12, 1.3 }

function Curvas.pace(etapa: number): number
	return PACE[math.clamp(etapa, 1, 4)]
end

function Curvas.peso(etapa: number, e1: number, e2: number, e3: number, e4: number): number
	local values = { e1, e2, e3, e4 }
	return values[math.clamp(etapa, 1, 4)]
end

return table.freeze(Curvas)
