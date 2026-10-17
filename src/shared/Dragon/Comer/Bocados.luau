--!strict
--[[
	Dragon/Comer/Bocados

	Lo que hace con cada pez (Dragon/Comer elige cuál, alternando lados). Todos
	empiezan cuando el pez llega a la boca: se lanza un poco hacia él (lunge, el
	cuadro del mordisco va de golpe), cierra la boca y la cola se enrosca hacia
	un lado. Al final abre bien la boca y echa la cabeza un poco atrás
	esperando el siguiente (anticipación). Con cada uno, aparte, el trago
	(trago: el bulto baja por el cuello, gulp2 y después gulp1, hasta el pecho,
	que se hincha; tragoQuieto es el mismo sin sonido). Variantes:
		arco   la cabeza traza un arco: sube un instante y cae sobre el pez; después
		       la echa atrás para tragar
		lado   lo atrapa de costado ladeando la cabeza y lo sacude como un cachorro
		       (la cría, con bounce de su etapa; el anciano casi no lo sacude)
		cielo  lo traga echando la cabeza al cielo, con un aletazo de alegría que
		       lo levanta un poco
	saludo (no es un bocado: va en su propia capa) le dedica el gesto al jugador
	de este cliente: ladea la cabeza hacia él, inclina el cuello, mueve la cola y
	levanta el ala de su lado.
	Eventos: chomp (al morder), gulp (el trago), savor (resoplido de gusto; con
	peces muy seguidos lo corta el siguiente) y dedicate (el saludo).
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Acto = require(script.Parent.Acto)

type Pose = Acto.Pose
type Ctx = Acto.Ctx

local HIT, BACK = 0.08, 0.42 -- el mordisco llega en HIT y vuelve hasta BACK (avance)

local function common(u: number, c: Ctx, k: number): Pose
	local hit = Acto.strike(u, HIT, BACK) * c.amp * k
	local wait = C.hold(u, 0.62, 0.85, 0.93, 1)
	local reach = 0.075 - 0.01 * (c.stage - 1) -- la cría se lanza más (en largos)
	return {
		lunge = reach * hit,
		jaw = 1.15 * wait,
		headSnap = 0.1 * wait,
		tailCurl = c.side * 0.45 * C.hold(u, 0.05, 0.35, 0.6, 1) * c.amp,
	}
end

local function events(savorAt: number): { { at: number, kind: string } }
	return { { at = 0, kind = "chomp" }, { at = savorAt, kind = "savor" } }
end

-- El trago: un bulto que baja por el cuello (gulp2 arriba, gulp1 abajo) hasta el
-- pecho, que se hincha. Va en su propia capa y no se corta: con peces seguidos
-- bajan varios a la vez, uno detrás de otro.
local function swallow(u: number, c: Ctx): Pose
	local g = C.span(u, 0.05, 0.75)
	local k = C.bell(g) * c.amp
	return {
		gulp2 = 0.14 * Acto.bump(g, 0.25, 0.2) * k,
		gulp1 = 0.14 * Acto.bump(g, 0.7, 0.2) * k,
		chest = 0.12 * C.bell(C.span(u, 0.55, 1)) * c.amp,
	}
end

local arco: Acto.Act = {
	name = "arco",
	seconds = 0.9,
	events = events(0.75),
	pose = function(u: number, c: Ctx): Pose
		local p = common(u, c, 1)
		local hit = Acto.strike(u, HIT, BACK) * c.amp
		local lift = C.bell(C.span(u, 0, 0.06)) * c.amp -- sube un instante antes de caer sobre él
		local toss = C.bell(C.span(u, 0.12, 0.6)) * c.amp
		p.neckSnap = -0.3 * hit + 0.18 * toss
		p.headSnap += -0.4 * hit + 0.15 * lift + 0.3 * toss
		p.tailUp = 0.2 * toss
		p.spread = 0.12 * C.bell(C.span(u, 0, 0.3)) * c.amp
		return p
	end,
}

local lado: Acto.Act = {
	name = "lado",
	seconds = 0.95,
	events = events(0.78),
	pose = function(u: number, c: Ctx): Pose
		local p = common(u, c, 0.85)
		local hit = Acto.strike(u, HIT, BACK) * c.amp
		local shake = math.sin(u * 30) * C.hold(u, 0.12, 0.18, 0.36, 0.5) * c.profile.bounce
		p.lookSnap = c.side * 0.28 * hit + 0.1 * shake * c.amp
		p.tilt = c.side * 0.35 * C.bell(C.span(u, 0, 0.55)) * c.amp
		p.neckSnap = -0.2 * hit
		p.headSnap += -0.25 * hit
		p.tailCurl = -(p.tailCurl or 0) -- la cola, al otro lado de la cabeza
		return p
	end,
}

local cielo: Acto.Act = {
	name = "cielo",
	seconds = 1.1,
	events = events(0.62),
	pose = function(u: number, c: Ctx): Pose
		local p = common(u, c, 0.9)
		local hit = Acto.strike(u, HIT, 0.36) * c.amp
		local toss = C.hold(u, 0.1, 0.32, 0.5, 0.8) * c.amp
		local up, down = C.bell(C.span(u, 0.18, 0.38)), C.bell(C.span(u, 0.38, 0.58))
		p.neckSnap = -0.2 * hit + 0.4 * toss
		p.headSnap += -0.3 * hit + 0.55 * toss
		p.pitch = 0.08 * toss
		p.spread = (0.4 * up - 0.3 * down) * c.amp
		p.rise = 0.04 * C.bell(C.span(u, 0.36, 0.95)) * c.amp
		p.tailUp = 0.3 * toss
		return p
	end,
}

local saludo: Acto.Act = {
	name = "saludo",
	seconds = 1.6,
	events = { { at = 0.22, kind = "dedicate" } },
	pose = function(u: number, c: Ctx): Pose
		local bow = C.hold(u, 0.1, 0.35, 0.65, 0.95)
		local wave = C.bell(C.span(u, 0.18, 0.62))
		local wag = math.sin(u * 14) * bow * (0.4 + 0.6 * c.profile.bounce)
		return {
			tilt = c.side * 0.32 * bow,
			head = -0.22 * bow,
			neck = -0.1 * bow,
			tailCurl = 0.35 * wag,
			[if c.side > 0 then "wingL" else "wingR"] = 0.35 * wave,
		}
	end,
}

local trago: Acto.Act = {
	name = "trago",
	seconds = 0.75,
	events = { { at = 0.12, kind = "gulp" } },
	pose = swallow,
}

local tragoQuieto: Acto.Act = { name = "trago", seconds = 0.75, events = {}, pose = swallow }

return table.freeze({
	trago = trago,
	tragoQuieto = tragoQuieto, -- el mismo, sin sonido (muchos peces seguidos)
	arco = arco,
	lado = lado,
	cielo = cielo,
	saludo = saludo,
})
