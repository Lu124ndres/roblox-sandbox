--!strict
--[[
	OrcaMotion/Tricks/Zambullida

	La zambullida honda con la cola afuera (fluke-up dive) de las ballenas y
	las orcas antes de una inmersión larga:
		1. una última respiración: sube un poco y sopla;
		2. arquea el lomo (arch +) y baja la cabeza: el lomo y la dorsal ruedan
		   sobre el agua;
		3. el cuerpo se pone casi vertical, cabeza abajo, y la cola sale del
		   agua con las aletas arriba, chorreando;
		4. se desliza abajo sin salpicar casi nada (la cola entra limpia) y da
		   un aletazo fuerte ya bajo el agua;
		5. nada en lo hondo, sube y, al salir, sopla fuerte (el aire de toda la
		   inmersión).
	Los gestos de la superficie duran lo mismo siempre para su tamaño (pace);
	lo que sobra de `seconds` es tiempo en lo hondo. `steep` es el ángulo máximo
	cabeza abajo: la anciana no cabe vertical en el lago y baja más acostada.
	La puede pedir el recorrido en su ciclo de respiración (Etapas: sounding).
	Marcas (avance u): soplo1, cola (la cola más alta), soplo2.
]]

local Respirar = require(script.Parent.Respirar)
local Tramos = require(script.Parent.Tramos)
local Tricks = require(script.Parent)

local smooth, span, bell, lerp, hermite =
	Tricks.smooth, Tricks.span, Tricks.bell, Tricks.lerp, Tricks.hermite

export type Style = {
	talla: Tricks.Talla?,
	steep: number?, -- ángulo máximo cabeza abajo (rad)
}

local STEEP = 1.35 -- rad (~77°): casi vertical, la cola arriba
local ARCH = 0.5 -- lomo arqueado al rodar sobre el agua (rad en toda la columna)
local ROLL_DEPTH = -0.15 -- el centro al rodar (altos)
local SLIDE = 0.9 -- cuánto se desliza abajo con la cola (altos)
-- Segundos de cada gesto para la adulta (las otras por su pace); respirar y soplar
-- duran el gesto entero (Respirar).
local T = { roll = 3, fluke = 2.6, slide = 2.8, ascend = 5 }
local MIN_DEEP = 1 -- segundos mínimos en lo hondo
local BIG_BLOW = 1.4 -- el soplo al volver es más fuerte
local BELLY = 0.3 -- la panza queda esto más abajo que el centro (altos)

local Zambullida = {}

function Zambullida.dive(depth: number, seconds: number, style: Style?): Tricks.Trick
	local s: Style = style or {}
	local steep = s.steep or STEEP
	local pace = if s.talla then s.talla.pace else 1
	local breath = Respirar.length(pace)
	local fixed = (T.roll + T.fluke + T.slide + T.ascend) * pace + 2 * breath
	local k = if seconds - fixed < MIN_DEEP then math.max(seconds - MIN_DEEP, 1) / fixed else 1
	pace *= k -- truco corto: todos los gestos más rápidos
	breath = Respirar.length(pace)
	local roll, fluke, slide, ascend =
		T.roll * pace, T.fluke * pace, T.slide * pace, T.ascend * pace
	local deep = math.max(MIN_DEEP, seconds - fixed * k)
	local fluked = ROLL_DEPTH - 0.5 * math.sin(steep) -- el centro con la cola arriba
	-- Se desliza SLIDE con la cola, pero no más hondo de lo pedido.
	local slid = math.max(fluked - SLIDE, math.min(-depth, fluked))
	local bottom = math.min(-depth, slid)
	local blowAt = Respirar.lead(pace)
	-- Rueda, cola afuera y se desliza: un solo gesto que fluye (nodos en segundos).
	local t1, t2, t3 = roll, roll + fluke, roll + fluke + slide
	local DEPTH = { 0, 0, t1, ROLL_DEPTH, t2, fluked, t3, slid } -- el 1.º: la de crucero
	local PITCH = { 0, 0, t1, -0.5, t2, -steep, t3, -steep * 0.75 }
	local ARCHED = { 0, 0, t1, ARCH, t2, 0.15, t3, 0 }
	local TAIL = { 0, 0, t1 + 0.3 * fluke, 0, t2, 0.35, t3, 0 }
	local FLUKES = { 0, 0, t1 + 0.4 * fluke, 0, t2, 0.3, t3, 0 }
	local curve = Tricks.curve

	local list: { Tramos.Tramo } = {
		{ -- 1. La última respiración.
			seconds = breath,
			pose = function(t: number, from: number, _seed: number): Tricks.Pose
				local pose: Tricks.Pose = { depth = from, effort = 0.6, speed = 0.8 }
				return Respirar.add(pose, t - blowAt, pace)
			end,
		},
		{ -- 2. Arquea el lomo y el lomo rueda sobre el agua; la cola sale vertical y se desliza.
			seconds = t3,
			pose = function(t: number, from: number, _seed: number): Tricks.Pose
				local out = span(t, t1, t3) -- la cola: sube sola y entra limpia
				return {
					depth = curve(t, DEPTH, from),
					pitch = curve(t, PITCH),
					arch = curve(t, ARCHED),
					tail = curve(t, TAIL),
					flukes = curve(t, FLUKES),
					head = -0.1 * smooth(t / t1),
					fins = 0.2 + 0.1 * smooth(t / t1),
					effort = if t < t2
						then 0.4 * (1 - smooth(t / t1)) + 0.1
						else 0.1 + 0.7 * bell(span(t, t2 + 0.5 * slide, t3)),
					speed = lerp(0.8, 0.5, smooth(t / t2)),
					splash = if out > 0 then 0.2 else nil,
				}
			end,
		},
		{ -- 3. Nada en lo hondo.
			seconds = deep,
			pose = function(t: number, _from: number, _seed: number): Tricks.Pose
				local a = t / deep
				return {
					depth = hermite(a, slid, 0, bottom, 0),
					pitch = lerp(-steep * 0.75, 0, smooth(span(a, 0, 0.6))),
					fins = 0.15,
					effort = 0.7,
					speed = 1,
				}
			end,
		},
		{ -- 4. Sube a respirar.
			seconds = ascend,
			pose = function(t: number, from: number, _seed: number): Tricks.Pose
				local a = t / ascend
				return {
					depth = hermite(a, bottom, 0, from, 0),
					pitch = 0.4 * bell(a),
					effort = 0.9,
					speed = 1,
				}
			end,
		},
		{ -- 5. Sopla fuerte al salir.
			seconds = breath,
			pose = function(t: number, from: number, _seed: number): Tricks.Pose
				local pose: Tricks.Pose = { depth = from, effort = 0.6, speed = 0.9 }
				return Respirar.add(pose, t - blowAt, pace, BIG_BLOW)
			end,
		},
	}
	local tailUp = breath + t2
	local back = Tramos.start(list, 5) + blowAt
	local moments: { Tramos.Moment } = {
		{ time = blowAt, kind = "spout" },
		{ time = tailUp + slide * 0.45, kind = "splash", size = 0.4 }, -- la cola entra
		{ time = back, kind = "spout", size = BIG_BLOW },
	}
	local marks = { soplo1 = blowAt, cola = tailUp, soplo2 = back }
	local extra = { show = tailUp, vary = 0, deep = -bottom + BELLY }
	return Tramos.build("zambullida", list, moments, marks, extra)
end

return table.freeze(Zambullida)
