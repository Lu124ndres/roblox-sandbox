--!strict
--[[
	Minotauro/Comer/Tipos

	Lo que comparten las reacciones al comer (Minotauro/Comer):
		Fed     lo que llega con cada pez (la misma forma que client/Giant/FedInfo:
		        de dónde vino, qué pez, su rareza —1 = común—, si lo dio el jugador
		        de este cliente y cuántos peces seguidos lleva)
		Ctx     lo que la reacción sabe de su etapa: hop (0..1, cuánto puede
		        despegarse del suelo: el becerro salta, la forma final no)
		Move    una reacción: dura seconds (por el pace de la etapa); prio 1 = un
		        bocado, 2 = pez raro, 3 = festejo de combo; takes, cuánto deja la pose
		        de comer de Minotauro/Pose (0 nada, 1 toda: los brazos quedan libres);
		        events, sus momentos con sonido o efecto (at: avance 0..1); pose(u,
		        ctx), lo que se suma a la pose para el avance u. Se escriben hacia su
		        izquierda; mirror() las da vuelta (el pez vino de su derecha).
]]

local Pose = require(script.Parent.Parent.Pose)

export type Fed = {
	from: Vector3,
	fishId: string,
	rarity: number,
	isLocal: boolean,
	streak: number,
}
export type Ctx = { hop: number }
export type Event = { at: number, kind: string }
export type Move = {
	name: string,
	seconds: number,
	prio: number,
	takes: number,
	events: { Event },
	pose: (u: number, ctx: Ctx) -> Pose.Pose,
}

-- Claves que cambian de lado al reflejar la pose y las que cambian de signo.
local SWAP = { "arm", "out", "elbow", "elbowOut", "leg", "knee", "foot", "ear", "faldon" }
local FLIP = { "sway", "tilt", "lookYaw", "tail1", "tail2", "tail3" }

local Tipos = {}

-- La misma pose del otro lado (izquierda por derecha).
function Tipos.mirror(p: Pose.Pose): Pose.Pose
	local out: Pose.Pose = table.clone(p)
	for _, base in SWAP do
		out[base .. "L"], out[base .. "R"] = p[base .. "R"], p[base .. "L"]
	end
	for _, key in FLIP do
		if p[key] then
			out[key] = -p[key]
		end
	end
	return out
end

return table.freeze(Tipos)
