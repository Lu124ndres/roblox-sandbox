--!strict
--[[
	Zorro/Comer/Clip

	Qué es una reacción al comer y las piezas que comparten:
		Clip   nombre, duración (en la etapa 1; las otras la estiran con pace),
		       eventos (at 0..1 → kind) y pose(u, ctx): lo que se suma a la pose
		       del zorro (Zorro/Pose) en el avance u. Todas empiezan y terminan en
		       cero: entran y salen sin saltos.
		Ctx    side (1 su izquierda, -1 su derecha: alterna para no repetir), lift
		       (cuánto salta, fracción del alto: la etapa grande salta menos),
		       radius (radio de la carrera, fracción del alto: cabe en el lago),
		       rarity (del pez que la provocó; un festejo grande usa 6) y stage
		       (1..4: la cría exagera, la forma final se mueve poco).
	Además de las claves de Zorro/Pose (y las de la cara y las colas del contrato
	de la ola 3: emo*, eyesClosed, blink, earTipL/R, lookHold, tailGusto), una
	reacción puede pedir:
		take        cuánto deja de lado la pose de comer (0..1)
		spinY       giro de todo el cuerpo sobre sí (rad, + a su izquierda)
		flip        vuelta de todo el cuerpo hacia atrás (rad: salto mortal)
		runX, runZ  corrimiento del cuerpo (fracción del alto, en su marco: -Z al
		            frente)
		gait        fase de las patas al correr (rad): cada media vuelta pisa
		trail       0..1: deja estela de agua
		morsel      0..1: mira el bocado (Pivote gira la cabeza hacia el pez)
	gallop() arma el galope con esa fase; spin y flip terminan en vueltas enteras;
	seq() pega dos reacciones (el gran festejo).
	mira() es la mirada al bocado: la cabeza va al pez y la Mirada deja de lado al
	jugador (lookHold) mientras lo atrapa y lo traga.
]]

local Curvas = require(script.Parent.Curvas)
local Pose = require(script.Parent.Parent.Pose)

export type Ctx = {
	side: number,
	lift: number,
	radius: number,
	rarity: number,
	stage: number,
}
-- rare: el evento solo sale si el pez es al menos así de raro (ctx.rarity).
export type Event = { at: number, kind: string, rare: number? }
export type Clip = {
	name: string,
	seconds: number,
	events: { Event },
	pose: (u: number, ctx: Ctx) -> Pose.Pose,
}

local Clip = {}

-- Galope: las delanteras juntas y después las traseras, el lomo se arquea y estira.
function Clip.gallop(phase: number, amount: number): Pose.Pose
	local front, hind = math.sin(phase), math.sin(phase + math.pi)
	return {
		stepFL = math.max(0, front) * amount,
		stepFR = math.max(0, math.sin(phase - 0.5)) * amount,
		stepHL = math.max(0, hind) * amount,
		stepHR = math.max(0, math.sin(phase + math.pi - 0.5)) * amount,
		lean = -0.07 * front * amount,
		dy = 0.025 * math.abs(front) * amount,
		gait = phase,
	}
end

-- Mira el bocado de a hasta b (avance u): la cabeza sigue al pez y la Mirada no
-- tira hacia el jugador; suelta despacio después de b.
function Clip.mira(u: number, a: number, b: number): Pose.Pose
	local on = Curvas.hold(u, a, a + 0.1, b, b + 0.2)
	return { morsel = on, lookHold = on }
end

-- Una reacción hecha de dos seguidas (la carrera y el salto mortal): sin soltar la
-- pose de comer entre las dos (take sigue en 1) y con los eventos de ambas.
function Clip.seq(name: string, a: Clip, b: Clip): Clip
	local part = a.seconds / (a.seconds + b.seconds)
	local events: { Event } = {}
	for _, e in a.events do
		table.insert(events, { at = e.at * part, kind = e.kind, rare = e.rare })
	end
	for _, e in b.events do
		table.insert(events, { at = part + e.at * (1 - part), kind = e.kind, rare = e.rare })
	end
	return {
		name = name,
		seconds = a.seconds + b.seconds,
		events = events,
		pose = function(u: number, ctx: Ctx): Pose.Pose
			local p = if u < part
				then a.pose(u / part, ctx)
				else b.pose((u - part) / (1 - part), ctx)
			p.take = Curvas.hold(u, 0, 0.04, 0.97, 1)
			return p
		end,
	}
end

-- Suma b dentro de a (ponderado) y devuelve a: para armar una pose con partes.
function Clip.mix(a: Pose.Pose, b: Pose.Pose, k: number?): Pose.Pose
	Pose.add(a, b, k)
	return a
end

return table.freeze(Clip)
