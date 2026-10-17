--!strict
--[[
	Dragon/Trucos

	Los trucos del dragón en el aire, uno por módulo, sincronizados por la hora
	del servidor (todos los ven a la vez). Cada `trickEvery` segundos puede
	empezar uno de los de su etapa (Dragon/Etapas), solo si la rutina lo tiene
	volando todo ese rato (Dragon/Rutina.flying). pose(u, L) da, para el avance u
	(0..1) y el largo L del dragón, lo que se suma a la pose de vuelo (Dragon/Pose)
	más speed (multiplica la velocidad), dy (studs arriba/abajo del recorrido),
	roll (giro sobre su eje, manda), flap (multiplica el aleteo), fold, hover y
	fire. Con los principios de docs/estilo_modelos.md (anticipación, arcos,
	rebote):
		rugido     junta aire con la cabeza abajo, se frena en el aire con
		           aletazos fuertes y ruge al cielo sacudiendo la cabeza
		fuego      toma aire echando la cabeza atrás, planea y echa fuego a la
		           lava barriendo en arco
		picada     sube un poco con las alas arriba, las pliega y se tira en
		           picada; abajo se recupera con aletazos fuertes
		voltereta  contragiro y una vuelta entera sobre su eje que se pasa y
		           vuelve (la cría)
		planeo     alas extendidas sin aletear, mirando la lava de lado a lado
	events: momentos con sonido o efecto (roar, fire, whoosh, flap).
]]

local Azar = require(script.Parent.Parent.Minotauro.Azar)
local Etapas = require(script.Parent.Etapas)

export type Pose = { [string]: number }
export type Trick = {
	name: string,
	seconds: number,
	events: { { at: number, kind: string } },
	pose: (u: number, L: number) -> Pose,
}

local TRICKS: { [string]: Trick } = {
	rugido = require(script.Rugido),
	fuego = require(script.Fuego),
	picada = require(script.Picada),
	voltereta = require(script.Voltereta),
	planeo = require(script.Planeo),
}

local SKIP = 0.22 -- parte de los tramos sin truco

local Trucos = {}

-- El truco del tramo de `now` (o nil), su avance 0..1, el tramo y cuándo empieza y termina.
function Trucos.current(
	now: number,
	profile: Etapas.Profile
): (Trick?, number, number, number, number)
	local every = profile.trickEvery
	local slot = math.floor(now / every)
	if Azar.unit(slot, 21) < SKIP then
		return nil, 0, slot, 0, 0
	end
	local trick = TRICKS[profile.tricks[Azar.pick(#profile.tricks, slot, 22)]]
	local start = slot * every + every * 0.25
	local u = (now - start) / trick.seconds
	if u < 0 or u > 1 then
		return nil, 0, slot, 0, 0
	end
	return trick, u, slot, start, start + trick.seconds
end

-- El truco de ahora como pose (o nil) si `allowed` deja volar libre de principio a
-- fin; sus eventos van a `out` (tracker recuerda hasta dónde ya sonaron).
export type Tracker = { slot: number, u: number }
function Trucos.play(
	tracker: Tracker,
	now: number,
	profile: Etapas.Profile,
	L: number,
	allowed: (at: number) -> boolean,
	out: { { kind: string } }
): Pose?
	local trick, u, slot, from, to = Trucos.current(now, profile)
	if not trick or not (allowed(from) and allowed(to)) then
		return nil
	end
	if slot ~= tracker.slot then
		tracker.slot, tracker.u = slot, u
	end
	for _, event in trick.events do
		if event.at > tracker.u and event.at <= u then
			table.insert(out, { kind = event.kind })
		end
	end
	tracker.u = u
	return trick.pose(u, L)
end

return table.freeze(Trucos)
