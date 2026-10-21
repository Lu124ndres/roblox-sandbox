--!strict
--[[
	OrcaMotion/Tricks/Surface

	Trucos en la superficie, como los de las orcas de verdad:
		tailSlap  coletazo (lobtail): mete la cabeza, saca la cola y la azota
		          `count` veces; cada golpe sube lento (anticipación), baja
		          acelerando (golpe) y rebota (recuperación), y el cuerpo se
		          inclina con la cola.
		finSlap   aletazo: se acuesta de costado y golpea el agua con la
		          pectoral de arriba (el azar elige el lado); el cuerpo se mece
		          con cada golpe.
		logging   descansa flotando casi quieta, el lomo afuera, mecida por el
		          agua; sopla despacio `blows` veces y le muestra el costado a
		          la rampa.
]]

local Respirar = require(script.Parent.Respirar)
local Tricks = require(script.Parent)

local smooth, span, lerp = Tricks.smooth, Tricks.span, Tricks.lerp

export type Style = {
	talla: Tricks.Talla?,
	size: number?, -- fuerza de los golpes (1 normal)
	pitch: number?, -- coletazo: cabeza abajo (rad, negativo; la anciana no cabe tan parada)
}

local RAISE, STRIKE = 0.62, 0.78 -- cada golpe: sube hasta el 62 %, pega en el 78 %, rebota
local IN, OUT = 0.2, 0.85 -- avance en que empiezan y terminan los golpes
local HEAD_DOWN = -0.85 -- coletazo: cabeza abajo, cola afuera (rad)
local TAIL_DOWN = 0.4 -- y el centro hundido (altos)
local SIDE_ROLL = 1.35 -- aletazo: acostada de costado (rad)
local LOG_DEPTH = -0.1 -- flotando: el lomo y la dorsal afuera (altos)
local SWELL, SWELL_SECONDS = 0.012, 4.5 -- el oleaje la mece (altos, s)
local AMP = 0.2 -- la fuerza de los golpes cambia ±10 % con el azar

local Surface = {}

-- Un golpe en su tramo f (0..1): +1 arriba, -1 pegando, vuelve a 0.
local function lash(f: number): number
	if f < RAISE then
		return smooth(f / RAISE) -- sube lento
	elseif f < STRIKE then
		local a = (f - RAISE) / (STRIKE - RAISE)
		return 1 - 2 * a * a -- baja acelerando: el golpe
	end
	return -1 + smooth((f - STRIKE) / (1 - STRIKE)) -- rebota y se acomoda
end

-- Golpes en su tramo y los eventos de cada uno.
local function blows(u: number, count: number): number
	if u <= IN or u >= OUT then
		return 0
	end
	return lash((span(u, IN, OUT) * count) % 1)
end
local function hits(count: number, kind: string, where: string, size: number?): { Tricks.Event }
	local events: { Tricks.Event } = {}
	for k = 0, count - 1 do
		local at = IN + (OUT - IN) * (k + STRIKE) / count
		table.insert(events, { at = at, kind = kind, where = where, size = size })
	end
	return events
end

function Surface.tailSlap(count: number, seconds: number, style: Style?): Tricks.Trick
	local size = if style then style.size else nil
	local talla = if style and style.talla then style.talla else Tricks.ADULTA
	local down = if style and style.pitch then style.pitch else HEAD_DOWN
	return {
		name = "coletazo",
		seconds = seconds,
		events = hits(count, "slap", "tail", size),
		vary = 0.15,
		show = 0.5,
		deep = TAIL_DOWN + talla.half * math.sin(-down), -- el hocico, cabeza abajo
		pose = function(u: number, from: number, seed: number?): Tricks.Pose
			local hold = smooth(span(u, 0, IN)) * (1 - smooth(span(u, OUT, 1)))
			local l = blows(u, count) * (1 + AMP * ((seed or 0.5) - 0.5))
			return {
				depth = lerp(from, -TAIL_DOWN, hold),
				pitch = (down - 0.06 * l) * hold, -- se inclina con la cola
				tail = (0.45 + 0.5 * l) * hold,
				flukes = 0.3 * l * hold,
				arch = (-0.2 * math.max(l, 0) + 0.12 * math.max(-l, 0)) * hold,
				fins = -0.3 * hold, -- abiertas para sostenerse
				effort = 0.15,
				speed = 0.2,
			}
		end,
	}
end

function Surface.finSlap(count: number, seconds: number, style: Style?): Tricks.Trick
	local size = if style then style.size else nil
	return {
		name = "aletazo",
		seconds = seconds,
		events = hits(count, "slap", "fin", size),
		vary = 0.15,
		show = 0.5,
		pose = function(u: number, from: number, seed: number?): Tricks.Pose
			local s = seed or 0.5
			local side = if s < 0.5 then 1 else -1 -- roll + sube la derecha
			local lie = smooth(span(u, 0, 0.18)) * (1 - smooth(span(u, OUT, 1)))
			local l = blows(u, count) * (1 + AMP * (s - 0.5))
			local upper, lower = (-0.1 - 0.7 * l) * lie, 0.25 * lie -- - = arriba, + = pega
			return {
				depth = lerp(from, -0.1, lie),
				roll = side * (SIDE_ROLL + 0.07 * l) * lie, -- se mece con cada golpe
				fin = if side > 0
					then { der = upper, izq = lower }
					else { izq = upper, der = lower },
				fins = -0.2 * lie,
				effort = 0.25,
				speed = 0.35,
			}
		end,
	}
end

function Surface.logging(seconds: number, count: number, style: Style?): Tricks.Trick
	local pace = if style and style.talla then style.talla.pace else 1
	local times: { number } = {}
	local events: { Tricks.Event } = {}
	for k = 1, count do
		local at = 0.12 + 0.76 * (k - 0.5) / count
		table.insert(times, at * seconds)
		table.insert(events, { at = at, kind = "spout" })
	end
	return {
		name = "flotar",
		seconds = seconds,
		events = events,
		vary = 0.15,
		pose = function(u: number, from: number, seed: number?): Tricks.Pose
			local s, t = seed or 0.5, u * seconds
			local lie = smooth(span(u, 0, 0.12)) * (1 - smooth(span(u, 0.88, 1)))
			local swell = SWELL * math.sin(2 * math.pi * t / SWELL_SECONDS)
			local pose: Tricks.Pose = {
				depth = lerp(from, LOG_DEPTH + swell, lie),
				pitch = 0.03 * lie,
				roll = 0.035 * math.sin(2 * math.pi * t / 7.3 + s * 6) * lie,
				tail = -0.08 * lie, -- la cola cuelga
				flukes = -0.06 * lie,
				fin = {
					izq = (-0.12 + 0.05 * math.sin(t * 0.8 + s * 4)) * lie,
					der = (-0.12 + 0.05 * math.sin(t * 0.7 + 2)) * lie,
				},
				effort = lerp(1, 0.05, lie), -- casi no aletea
				speed = lerp(1, 0.03, lie),
				face = lie,
				flank = true,
			}
			local near = times[1] or 0 -- el soplo más cercano
			for _, time in times do
				if math.abs(t - time) < math.abs(t - near) then
					near = time
				end
			end
			return Respirar.add(pose, t - near, pace)
		end,
	}
end

return table.freeze(Surface)
